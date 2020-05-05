package hxd.fmt.obj;

import haxe.io.Bytes;
import h3d.Vector;

class BytesToLines {
    public var bytes: Bytes;
    public var pos: Int;
    public var lineNum:Int;

    public function new(data: Bytes) {
        this.bytes = data;
        this.pos = 0;
        this.lineNum = 1;
    }

    public function nextLine(): String {
        if (pos == bytes.length) {
            return null;
        }
        var startPos = pos;

        // Scan to the next newline character
        while (pos < bytes.length) {
            var val = bytes.get(pos);
            if (val == "\n".code) {
                lineNum++;
                break;
            }
            pos++;
        }
        if (pos == bytes.length) {
            return bytes.getString(startPos, bytes.length-startPos);
        }
        var endPos = pos;
        pos++;

        return bytes.getString(startPos, endPos-startPos);
    }

    public static function splitVals(line: String): Array<String> {
        if (line.length == 0)
            return [];

        var tempSplit = line.split(" ");
        var retArray: Array<String> = [];

        for (val in tempSplit) {
            var trimmed = StringTools.trim(val);
            if (trimmed.length == 0)
                continue;
            retArray.push(trimmed);
        }
        return retArray;
    }

}

typedef FaceVert = {v:Int, t:Null<Int>, n:Null<Int>};
typedef Face = {verts: Array<FaceVert>, smooth:Bool};
typedef FaceMatMap = Map<String, Array<Face>>;

class ObjParser {

    var lines: BytesToLines;

    public var name: String;
    public var verts: Array<Vector>;
    public var normals: Array<Vector>;
    public var texCoords: Array<Vector>;
    public var faces: FaceMatMap;
    var currentMat: String;

    public var matlibs: Array<String>;

    var isSmooth: Bool;

    private function new(name: String, data: Bytes) {
        this.lines = new BytesToLines(data);

        this.name = name;
        this.verts = [];
        this.normals = [];
        this.texCoords = [];
        this.faces = new Map();

        this.matlibs = [];

        this.isSmooth = false;
        this.currentMat = "";
    }

    private function parseFile() {
        while(true) {
            var line = lines.nextLine();
            if (line == null) {
                break;
            }
            var vals = BytesToLines.splitVals(line);
            if (vals.length == 0) {
                continue;
            }
            switch(vals[0]) {
            case "v":
                parseVert(vals);
            case "vt":
                parseTexCoord(vals);
            case "vn":
                parseNormal(vals);
            case "f":
                parseFace(vals);
            case "s":
                parseSmooth(vals);
            case "usemtl":
                parseMaterial(vals);
            case "mtllib":
                parseMaterialLib(vals);
            case "o":
                continue; // ignore objects
            case "g":
                continue; // ignore groups
            case "#":
                continue; // ignore comments (obviously)
            default:
                //trace(vals[0]);
            }
        }
        fillNormals();
        fillTexCoords();
    }

    private function parseMaterialLib(vals:Array<String>) {
        if (vals.length != 2)
            throw 'Invalid mtllib line. Line ${lines.lineNum}';

        this.matlibs.push(vals[1]);

    }

    private function parseMaterial(vals:Array<String>) {
        if (vals.length != 2)
            throw 'Invalid usemtl line. Line ${lines.lineNum}';

        currentMat = vals[1];
        // if (faces.get(currentMat) == null) {
        //     faces.set(currentMat, []);
        // }
    }

    private function parseSmooth(vals:Array<String>) {
        if (vals.length != 2)
            throw 'Invalid smooth line. Line ${lines.lineNum}';

        if (vals[1] == "1" || vals[1] == "on") {
            isSmooth = true;
        }
        if (vals[1] == "0" || vals[1] == "off") {
            isSmooth = false;
        }
    }

    private function parseVert(val: Array<String>) {
        if (val.length < 4)
            throw 'Vert is less than 3 values. Line ${lines.lineNum}';

        var x = Std.parseFloat(val[1]);
        var y = Std.parseFloat(val[2]);
        var z = Std.parseFloat(val[3]);
        var w = (val.length > 4) ? Std.parseFloat(val[4]) : 1.0;

        this.verts.push(new Vector(x,y,z,w));
    }

    private function parseTexCoord(val: Array<String>) {
        if (val.length < 2)
            throw 'TexCoord without value. Line ${lines.lineNum}';

        var u = Std.parseFloat(val[1]);
        var v = (val.length > 3) ? Std.parseFloat(val[3]) : 0.0;
        var w = (val.length > 4) ? Std.parseFloat(val[4]) : 0.0;

        this.texCoords.push(new Vector(u,v,w,1.0));
    }

    private function parseNormal(val: Array<String>) {
        if (val.length != 4)
            throw 'Normals must have 3 values. Line ${lines.lineNum}';

        var x = Std.parseFloat(val[1]);
        var y = Std.parseFloat(val[2]);
        var z = Std.parseFloat(val[3]);

        var normal = new Vector(x,y,z,1.0);
        normal.normalize();

        this.normals.push(normal);
    }
    private function parseFaceVert(val: String):FaceVert {

        var indices = val.split("/");
        if (indices.length < 1 || indices.length > 3)
            throw 'Error parsing face on line: ${lines.lineNum}';

        var v = Std.parseInt( (indices.length > 0)? indices[0] : "");
        var t = Std.parseInt( (indices.length > 1)? indices[1] : "");
        var n = Std.parseInt( (indices.length > 2)? indices[2] : "");

        if (v == null || v == 0)
            throw 'Error parsing face on line: ${lines.lineNum}';

        // Convert the indices to absolute, 0-based indices (see spec)
        v = (v<0)? verts.length +v : v-1;
        if (t!= null) {
            t = (t<0)? texCoords.length +t : t-1;
        }
        if (n != null) {
            n = (n<0)? normals.length +n : n-1;
        }

        return {v:v, t:t, n:n};
    }

    private function parseFace(vals: Array<String>) {
        if (vals.length < 4)
            throw 'Faces with less than 3 vertices. Line ${lines.lineNum}';

        var verts = [];
        for(i in 1...vals.length) {
            var vert = parseFaceVert(vals[i]);
            verts.push(vert);
        }
        var faceList = faces[currentMat];
        if (faceList == null) {
            faceList = [];
            faces[currentMat] = faceList;
        }

        // Convert this polygon into a triangle fan
        for (i in 2...verts.length) {
            var triVerts = [verts[0], verts[i-1], verts[i]];
            faceList.push( {verts: triVerts, smooth: isSmooth} );
        }
    }

    private function genNormal(face) {
        var v0 = verts[face.verts[0].v];
        var v1 = verts[face.verts[1].v];
        var v2 = verts[face.verts[2].v];
        var edge0 = v1.sub(v0);
        var edge1 = v2.sub(v0);
        var norm = edge0.cross(edge1);
        norm.normalize();
        return norm;
    }

    private function fillTexCoords() {
        var defIndex = texCoords.length;
        texCoords.push(new Vector(0.5, 0.5, 0,1));

        // Set all empty tex coords to the default
        for (_ => fs in faces) {
            // TODO: validate this is safe by checking that
            // the materials do not use textures
            for (face in fs) {
                for (v in face.verts) {
                    if (v.t == null) {
                        v.t = defIndex;
                    }
                }
            }
        }
    }

    private function fillNormals() {

        for (_ => fs in faces) {
            for (face in fs) {
                // TODO: handle smooth faces
                var needsNormal = false;
                for (v in face.verts) {
                    if (v.n == null)
                        needsNormal = true;
                }
                if (!needsNormal) continue;
                var norm = genNormal(face);

                var normInd = normals.length;
                normals.push(norm);
                for (v in face.verts) {
                    if (v.n == null)
                        v.n = normInd;
                }
            }
        }
    }

    public static function parse(name: String, file: haxe.io.Bytes): ObjParser {

        //var bytes = sys.io.File.getBytes(file);
        var parser = new ObjParser(name, file);
        parser.parseFile();
        return parser;
    }
}

class Material {
    public var diffTex: String;
    public var name:String;

    public function new(name: String) {
        this.name = name;
    }
}

class MTLParser {

    var lines: BytesToLines;
    var curMat: Material;
    var matList: Map<String, Material>;

    private function new(data:Bytes) {
        this.lines = new BytesToLines(data);
        matList = new Map();
    }

    public static function parse(file: haxe.io.Bytes) : Map<String, Material> {
        var parser = new MTLParser(file);
        return parser.parseFile();
    }
    function parseFile() : Map<String, Material> {

        while(true) {
            var line = lines.nextLine();
            if (line == null) {
                break;
            }
            var vals = BytesToLines.splitVals(line);
            if (vals.length == 0) {
                continue;
            }
            switch(vals[0]) {
            case "newmtl":
                newMat(vals);
            case "Kd":
                parseDiffCol(vals);
            case "map_Kd":
                parseDiffTex(vals);
            default:
                continue;
            }
        }

        return matList;
    }
    function newMat(vals: Array<String>) {

        if (vals.length != 2) {
            throw 'Invalid newmtl line. Line ${lines.lineNum}';
        }
        curMat = new Material(vals[1]);
        matList.set(vals[1], curMat);

    }
    function parseDiffCol(vals: Array<String>) {
        if (vals.length != 4) {
            throw 'Invalid Kd line. Line ${lines.lineNum}';
        }
        var r = Std.parseFloat(vals[1]);
        var g = Std.parseFloat(vals[2]);
        var b = Std.parseFloat(vals[3]);
        if (r > 1.0 || r < 0.0) {
            throw 'Invalid "r" param in Kd: ${vals[1]}';
        }
        if (g > 1.0 || g < 0.0) {
            throw 'Invalid "g" param in Kd: ${vals[2]}';
        }
        if (b > 1.0 || b < 0.0) {
            throw 'Invalid "b" param in Kd: ${vals[3]}';
        }
        // Convert to color value and encode in a false "filename"
        var rb = Std.int(r*255.0);
        var gb = Std.int(g*255.0);
        var bb = Std.int(b*255.0);
        var colVal = (rb << 16) + (gb << 8) + bb;
        var colStr =  h3d.mat.Texture.toColorString(colVal);
        curMat.diffTex = colStr;
    }

    function parseDiffTex(vals: Array<String>) {
        if (vals.length != 2) {
            throw 'Invalid map_Kd line. Line ${lines.lineNum}';
        }
        curMat.diffTex = vals[1];
    }
}
