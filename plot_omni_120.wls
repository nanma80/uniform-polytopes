#!/usr/bin/env wolframscript


dataFolder = "data";
imageFolder = "output";
epsilon = 0.0000001;
shape = "omni_120";
dataFileName = FileNameJoin[{dataFolder, shape <> ".wl"}];
rangeFactor = 0.35;
exportToPov = True;
imageSize = 150 * {4, 3};

Needs["POVRayRender`"];
ConfigurePOVRayRender["POVRayPath" -> "C:\\Program Files\\POV-Ray\\v3.7\\bin\\pvengine64.exe"];

colors = Join[{Red, Blue, Green, Yellow, Magenta, Cyan, Brown, Orange, Pink, Purple}, RandomColor[10]];
getProjectionMatrix[direction_] := Simplify[Orthogonalize[{direction, {1, 0, 0, 0}, {0, 1, 0, 0}, {0, 0, 1, 0}}]][[2;;4]];
projectTo3d[vertex4d_] := {vertex4d[[1]], vertex4d[[2]], vertex4d[[3]]};
reflect[point_, mirror_] := Simplify[point - 2 * (point.mirror)/(mirror.mirror)*mirror];
doubleReflect[point_, mirror1_, mirror2_] := reflect[reflect[point, mirror1], mirror2];
getEdgesFromFace[face_] := Table[{face[[i+1]], face[[Mod[i+1, Length[face]] + 1]]}, {i, 0, Length[face] - 1}];
explodedFace[face_, explosionFactor_] := Map[(# + Mean[face] * explosionFactor)&, face];
sameVertex[point1_, point2_] := point1 == point2;
sameNVertex[point1_, point2_] := Norm[N[point1] - N[point2]] < epsilon;
sameCenter[edge1_, edge2_] := Total[edge1] == Total[edge2];
sameCellCenter[cell1_, cell2_] := getCellCenter[cell1] == getCellCenter[cell2];
sameNCellCenter[cell1_, cell2_] := Norm[getCellCenter[N[cell1]] - getCellCenter[N[cell2]]] < epsilon;
getCellCenter[cell_] := Mean[Flatten[cell, 1]];

phi = (1 + Sqrt[5])/2;

cells = Get[dataFileName];
Print["cells: " <> IntegerString[cells//Length]];

faces = Flatten[cells, 1];
Print["faces: " <> IntegerString[faces//Length]];

edges = Union[ Flatten[Map[getEdgesFromFace, faces], 1], SameTest -> sameCenter];
Print["edges: " <> IntegerString[edges//Length]];

vertices = Union[ Flatten[faces, 1], SameTest -> sameVertex];
Print["vertices: " <> IntegerString[vertices//Length]];

color = colors[[1]];
thickness = Norm[cells[[1]][[1]][[1]]] * 0.008;
range = Norm[cells[[1]][[1]][[1]]] * rangeFactor;
lighting = {{"Point", White, {10, -10, 10}}};

graph = Graphics3D[
    {
        {
            Opacity[0.4], FaceForm[Lighter[color, 0.3]], Map[Polygon, Map[projectTo3d, faces, {2}]]
        },
        {
            FaceForm[White], Map[Cylinder[#, thickness]&, Map[projectTo3d, edges, {2}]]
        },
        {
            FaceForm[White], Map[Sphere[#, thickness * 2]&, Map[projectTo3d, vertices]]
        }
    },
    ViewPoint -> {3, -4, 5}*3,
    PlotRange -> {{-range, range}, {-range, range}, {-range, range}},
    Lighting -> lighting
];

outputFolder = FileNameJoin[{imageFolder, shape}];
If[!DirectoryQ[outputFolder], CreateDirectory[outputFolder]];

outputFileName = shape <> "_all.png";
outputFileName = FileNameJoin[{outputFolder, outputFileName}];
cropCommand = "mogrify -crop " <> IntegerString[imageSize[[2]]] <> "x" <> IntegerString[imageSize[[2]]] <> "+" <> IntegerString[(imageSize[[1]]-imageSize[[2]])/2] <> "+0 " <> outputFileName;

If[exportToPov,
    If[FileExistsQ[outputFileName], DeleteFile[outputFileName]];
    POVRayRender[graph, Method -> "Triangle", OutputPath -> outputFileName, ImageSize -> imageSize, RenderOptions -> "+A0.001 -J +UA"];
    Run[cropCommand];
    ,
    Export[outputFileName, graph];
]
Print["Saved the image to " <> outputFileName];
