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
plotNet = True;

selectedCellSides = {14, 8};
selectedCellSides = {14, 8, 62};
selectedCellSides = {14, 8, 62, 12};
colors = {Red, Blue, Green, Yellow};

(* only center *)
(* selectedCellSides = {62};
colors = {Green}; *)

(* comment out one or two of the lines below *)
(* showFaces = False; *)
showWireframe = False;


Needs["POVRayRender`"];
ConfigurePOVRayRender["POVRayPath" -> "C:\\Program Files\\POV-Ray\\v3.7\\bin\\pvengine64.exe"];

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
getAngle[v1_, v2_] := ArcCos[v1.v2/Norm[v1]/Norm[v2]];
rotateCell[cell_, centerCell_] := Module[
    {intFace, intFaceCenter, wDirection, vertexCenter, angle, xyzDirection, rotMat},
    intFace = Intersection[centerCell, cell, SameTest -> sameCenter][[1]];
    intFaceCenter = Mean[intFace]//Simplify;

    wDirection = {0, 0, 0, 1};
    vertexCenter = getCellCenter[cell];
    angle = getAngle[wDirection, vertexCenter]//Simplify;
    xyzDirection = vertexCenter - (vertexCenter.wDirection)*wDirection//Simplify;
    xyzDirection = xyzDirection/Norm[xyzDirection]//Simplify;

    rotMat = IdentityMatrix[4] - Transpose[{wDirection, xyzDirection}].{wDirection, xyzDirection} + Transpose[{wDirection, xyzDirection}].RotationMatrix[angle].{wDirection, xyzDirection};
    Map[#.rotMat + intFaceCenter.(IdentityMatrix[4] - rotMat)&, cell, {2}]
];


phi = (1 + Sqrt[5])/2;

cells = Get[dataFileName];
Print["Total cell count: " <> IntegerString[cells//Length]];
cellTypes = Tally[Map[Length, cells]];
Map[Print[IntegerString[#[[1]]] <> "-hedron * " <> IntegerString[#[[2]]]]&, cellTypes];

thickness = Norm[cells[[1]][[1]][[1]]] * 0.002;
range = Norm[cells[[1]][[1]][[1]]] * rangeFactor;
lighting = {{"Point", White, {10, -10, 10}}};

If[plotNet,
    Print["rotating cells to make net"];
    centerCell = Select[cells, (Length[#] == 62 &)][[1]];
    cells = Map[If[Length[#] == 62, #, rotateCell[#, centerCell]]&, cells]
];

selectedCells = {};
For[i=1, i<= Length[selectedCellSides], i++,
    AppendTo[selectedCells, Select[cells, (Length[#] == selectedCellSides[[i]] &)]];
];

Print["Selected cell counts"];
Print[Length/@selectedCells];

selectedFaces = Map[Flatten[#, 1]&, selectedCells];
Print["face counts"];
Print[Length/@selectedFaces];

If[showWireframe,
    selectedEdges = Map[
         Flatten[Map[getEdgesFromFace, #], 1]&,
        selectedFaces];
    Print["edge counts"];
    Print[Length/@selectedEdges];

    selectedVertices = Map[
        Flatten[#, 1]&,
        selectedFaces
    ];
    Print["vertices counts"];
    Print[Length/@selectedVertices];
];

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
                    If[plotNet, "_net", ""] <>
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
