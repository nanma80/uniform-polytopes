#!/usr/bin/env wolframscript


dataFolder = "data";
imageFolder = "output";
epsilon = 0.0000001;
shape = "omni_120";
dataFileName = FileNameJoin[{dataFolder, shape <> ".wl"}];
rangeFactor = 0.35;
exportToPov = True;
imageSize = 150 * {4, 3};
faceOpacity = 1.0;
showFaces = True;
showWireframe = True;

selectedCellSides = {14, 8};
selectedCellSides = {14, 8, 62};
(* selectedCellSides = {14, 8, 62, 12}; *)

(* comment out one or two of the lines below *)
(* showFaces = False; *)
showWireframe = False;


Needs["POVRayRender`"];
ConfigurePOVRayRender["POVRayPath" -> "C:\\Program Files\\POV-Ray\\v3.7\\bin\\pvengine64.exe"];

colors = {Red, Blue, Green, Yellow};
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
Print["Total cell count: " <> IntegerString[cells//Length]];
cellTypes = Tally[Map[Length, cells]];
Map[Print[IntegerString[#[[1]]] <> "-hedron * " <> IntegerString[#[[2]]]]&, cellTypes];

selectedCells = {};
For[i=1, i<= Length[selectedCellSides], i++,
    AppendTo[selectedCells, Select[cells, (Length[#] == selectedCellSides[[i]] &)]];
];

Print["Selected cell counts"];
Print[Length/@selectedCells];

selectedFaces = Map[Flatten[#, 1]&, selectedCells];
Print["face counts"];
Print[Length/@selectedFaces];

selectedEdges = Map[
    Union[ Flatten[Map[getEdgesFromFace, #], 1], SameTest -> sameCenter]&,
    selectedFaces];
Print["edge counts"];
Print[Length/@selectedEdges];

selectedVertices = Map[
    Union[ Flatten[#, 1], SameTest -> sameVertex]&,
    selectedFaces
];
Print["vertices counts"];
Print[Length/@selectedVertices];

thickness = Norm[cells[[1]][[1]][[1]]] * 0.002;
range = Norm[cells[[1]][[1]][[1]]] * rangeFactor;
lighting = {{"Point", White, {10, -10, 10}}};

graphElements = {};

For[ typeIndex = 1, typeIndex <= Length[selectedCells], typeIndex++,
    If[showFaces,
        AppendTo[graphElements,
            {
                Opacity[faceOpacity], FaceForm[Lighter[colors[[typeIndex]], 0.2]], 
                Map[Polygon, Map[projectTo3d, selectedFaces[[typeIndex]], {2}]]
            }
        ];
    ];

    If[showWireframe,
        AppendTo[graphElements,
            {
                FaceForm[White], 
                Map[Cylinder[#, thickness]&, Map[projectTo3d, selectedEdges[[typeIndex]], {2}]]
            }
        ];

        AppendTo[graphElements,
            {
                FaceForm[White], 
                Map[Sphere[#, thickness * 2]&, Map[projectTo3d, selectedVertices[[typeIndex]]]]
            }
        ];
    ];
];

graph = Graphics3D[
    graphElements,
    ViewPoint -> {3, -3, 0} * 10,
    ViewVertical -> {1, 0, phi},
    PlotRange -> {{-range, range}, {-range, range}, {-range, range}},
    Lighting -> lighting
];

outputFolder = FileNameJoin[{imageFolder, shape}];
If[!DirectoryQ[outputFolder], CreateDirectory[outputFolder]];

outputFileName = shape <> 
                    If[showFaces, "_faces", ""] <> 
                    If[showWireframe, "_wireframe", ""] <> 
                    "_" <> IntegerString[Length[selectedCells]] <>
                    ".png";
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
