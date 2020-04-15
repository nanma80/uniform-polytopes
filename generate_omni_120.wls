#!/usr/bin/env wolframscript


dataFolder = "data";
AllCells = True;
epsilon = 0.0000001;
dataFileName = FileNameJoin[{dataFolder, "omni_120.wl"}];

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
getFace[initialEdges_, mirrors_] := Module[
	{face1, countStart, i, mirrorIndex, edgeMap, edge, vertices},

	face1 = Simplify[initialEdges];

	countStart = -1;
	For[i=0, i < 100 && countStart != Length[face1], i++,
		countStart = Length[face1];
		
		For[mirrorIndex = Length[mirrors], mirrorIndex >= 1, mirrorIndex--,
			face1 = Union[face1, Map[reflect[#, mirrors[[mirrorIndex]] ]&, face1, {2}], 
				SameTest -> sameCenter];
		];
		face1 = face1//Simplify;
	];

	edgeMap = <||>;
	For[i = 1, i<= Length[face1], i++,
		edge = face1[[i]]//Simplify;
		If[KeyExistsQ[edgeMap, edge[[1]]], 
			AppendTo[edgeMap[edge[[1]]], edge[[2]] ],
			edgeMap[edge[[1]]] = { edge[[2]] }
		];
		If[KeyExistsQ[edgeMap, edge[[2]]], 
			AppendTo[edgeMap[edge[[2]]], edge[[1]] ],
			edgeMap[edge[[2]]] = { edge[[1]] }
		];
	];

	If[Length[edgeMap] != Length[face1], Throw["edgeMap does not match face1"]];
	flatFace1 = face1[[1]];

	For[i = 2, i <= Length[face1] - 1, i++,
		If[KeyExistsQ[ edgeMap, flatFace1[[i]]],
			neighbors = edgeMap[flatFace1[[i]]];
			If[Norm[N[neighbors[[1]]] - flatFace1[[i-1]]] < epsilon,
				AppendTo[flatFace1, neighbors[[2]]],
				AppendTo[flatFace1, neighbors[[1]]]
			]
			, Throw["Error: Cannot find vertex in edgeMap"];
		]
	];

	(* validate *)
	vertices = Union[ flatFace1, SameTest -> sameVertex ];
	If[Length[vertices] != Length[flatFace1], 
		Throw["Error: flatFace1 generation is incorrect"]
	];

	If[Length[vertices] != Length[face1], 
		Throw["Error: vertices in flatFace1 are incorrect"]
	];

	flatFace1
];

getCell[initialFaces_, activeMirrors_] := Module[
    {countStart, i, mirrorIndex},
    cell = Simplify[initialFaces];
    countStart = -1;
    For[i = 0, i < 100 && countStart != Length[cell], i++,
        countStart = Length[cell];
        For[mirrorIndex = Length[activeMirrors], mirrorIndex >= 1, mirrorIndex--,
            (* Print[{countStart, mirrorIndex}]; *)
            cell = Union[cell, Map[reflect[#, activeMirrors[[mirrorIndex]] ]&, cell, {2}], 
                SameTest -> sameCenter];
        ];
    ];
    cell
];


phi = (1 + Sqrt[5])/2;

vertex1 = {1, 1, 1 + 4 phi, 5 + 12 phi};
mirrors = {
	{0, 1, 0, 0	},
	{1, phi, -1/phi, 0	},
	{1, -phi, 1/phi, 0	},
	{1, 0, phi, -1/phi	}
};

Print["generating neighbors of vertex1"];
vertices = {vertex1};
countStart = -1;
For[i = 0, i < 2 && countStart != Length[vertices], i++,
	countStart = Length[vertices];
	For[mirrorIndex = 4, mirrorIndex >= 1, mirrorIndex--,
		vertices = Union[vertices, Map[reflect[#, mirrors[[mirrorIndex]] ]&, vertices], 
			SameTest -> sameNVertex];
	];
	Print[{i, Length[vertices]}];
];

neighbors = Select[vertices, Abs[Norm[N[#] - vertex1] - 2] < epsilon &];

neighborMirrors = Map[#-vertex1&, neighbors]//Simplify;

neighborEdges = Map[{vertex1, reflect[vertex1, #]}&, neighborMirrors];

edgeIndices = Subsets[Range[4], {2}];
Print["edgeIndices"];
Print[edgeIndices];

neighborFaces = Map[getFace[neighborEdges[[#]], neighborMirrors[[#]]]&, edgeIndices];
Print["polygon sides"];
Print[Length/@neighborFaces];

neighborCells = {};
For[excludeMirrorIndex = 1, excludeMirrorIndex <= 4 , excludeMirrorIndex++,
    mirrorIndices = Complement[Range[4], {excludeMirrorIndex}];
    initialFaceIndices = Select[ Range[Length[edgeIndices]], ContainsAll[mirrorIndices, edgeIndices[[#]]]&];
    newCell = getCell[neighborFaces[[initialFaceIndices]], neighborMirrors[[mirrorIndices]]];
    Print["new cell:"];
    Print[Length[newCell]];
    Print[Tally[Map[Length, newCell]]];
    AppendTo[neighborCells, newCell];
];

cells = neighborCells;
countStart = -1;
mirrorCount = 3;

For[i=0, i < 100 && countStart != Length[cells], i++,
    countStart = Length[cells];

    For[mirrorIndex = 1, mirrorIndex <= mirrorCount, mirrorIndex++,
        Print[{i, mirrorIndex, Length[cells]}];
        cells = Union[cells, Map[reflect[#, mirrors[[mirrorIndex]] ]&, cells, {3}], SameTest -> sameNCellCenter];
        cells = Simplify[cells];
    ];
    Print["Generated " <> IntegerString[Length[cells]] <> " cells so far."];
];

Print["There are " <> IntegerString[Length[cells]] <> " cells in total."];

If[FileExistsQ[dataFileName], DeleteFile[dataFileName]];
Save[dataFileName, cells];
Print["Saved cells to " <> dataFileName];
