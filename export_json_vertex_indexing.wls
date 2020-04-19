#!/usr/bin/env wolframscript

dataFolder = "data";
epsilon = 0.0000001;
shape = "omni_120";
dataFileName = FileNameJoin[{dataFolder, shape <> ".wl"}];

projectTo3d[vertex4d_] := {vertex4d[[1]], vertex4d[[2]], vertex4d[[3]]};
reflect[point_, mirror_] := FullSimplify[point - 2 * (point.mirror)/(mirror.mirror)*mirror];
doubleReflect[point_, mirror1_, mirror2_] := reflect[reflect[point, mirror1], mirror2];
getEdgesFromFace[face_] := Table[{face[[i+1]], face[[Mod[i+1, Length[face]] + 1]]}, {i, 0, Length[face] - 1}];
explodedFace[face_, explosionFactor_] := Map[(# + Mean[face] * explosionFactor)&, face];
sameVertex[point1_, point2_] := point1 == point2;
sameCenter[edge1_, edge2_] := Total[edge1] == Total[edge2];
sameCellCenter[cell1_, cell2_] := getCellCenter[cell1] == getCellCenter[cell2];
getCenter[edge_] := Total[edge];
getCellCenter[cell_] := Simplify[Total[Flatten[cell, 1]]];

toGoldenField[value_, lookupTable_] := 
	Intersection[lookupTable, {{N[value]}}, SameTest -> (Abs[(#1[[1]] - #2[[1]])] < epsilon&)][[1,2]];

getMap[list_] := Association[Table[{list[[k]] -> k}, {k, 1, Length[list]}]];

getIndexBasedPolytopeData[cells_] := Module[
	{
		cellsGoldenField, vertices, verticesMap, faces, edgesPerFace, edges, 
		edgeIndices, edgeCenters, edgeCentersMap, edgeCenterPerFace, faceIndices,
		faceCenters, faceCentersMap, faceCentersPerCell, cellIndices
	},
	
	Print["Converting " <> IntegerString[Length[cells]] <> " cells to index based."];
	possibleValues = Union[Flatten[cells], SameTest -> (Abs[N[#1]-N[#2]]<epsilon&)];
	filteredTable = Intersection[lookupTable, Table[{N[v]}, {v, possibleValues}], SameTest -> (Abs[(#1[[1]] - #2[[1]])] < epsilon&)];

	cellsGoldenField=Map[toGoldenField[#, filteredTable]&, cells, {4}];
	Print["Mapped values to the golden ratio field"];

	vertices = Union[Flatten[cellsGoldenField,2]];
	verticesMap = getMap[vertices];

	faces = Union[Flatten[cellsGoldenField,1], SameTest -> sameCenter];
	edgesPerFace = Map[getEdgesFromFace, faces];
	edges = Union[Flatten[edgesPerFace,1], SameTest -> sameCenter];
	edgeIndices = Map[Sort[Map[verticesMap, #]]&, edges];
	(* edgeCenters = Map[Total, edges]; *)
	(* edgeCentersMap = getMap[edgeCenters]; *)
	(* edgeCenterPerFace = Map[getCenter, edgesPerFace, {2}]; *)

	faceByVertexIndices = Map[Map[verticesMap, #]&, faces];

	(* faceIndices = Map[Sort[Map[edgeCentersMap, #]]&, edgeCenterPerFace]; *)
	faceCenters = Map[Total, faces];
	faceCentersMap = getMap[faceCenters];

	faceCentersPerCell = Map[Total[#, {2}]&, cellsGoldenField];
	cellIndices = Map[Sort[Map[faceCentersMap, #]]&, faceCentersPerCell];

	<|
		"vertices" -> vertices,
		"edges" -> edgeIndices - 1,
		"faces" -> faceByVertexIndices - 1,
		"cells" -> cellIndices - 1
	|>
];

phi = GoldenRatio;
numberLimit = {20, 12};
lookupTable = Flatten[Table[
	{N[i + j * GoldenRatio], {i, j}},
	{i, -numberLimit[[1]], numberLimit[[1]]},
	{j, -numberLimit[[2]], numberLimit[[2]]}
], 1];

outputFileName = shape <> "_vertex_indexing.json";
dataFileName = FileNameJoin[{dataFolder, shape <> ".wl"}];
outputFileName = FileNameJoin[{dataFolder, outputFileName}];

Print["Reading data for " <> shape <> " from " <> dataFileName];

inputData = Get[dataFileName];

scalingFactor = 1;
allData = getIndexBasedPolytopeData[inputData * scalingFactor];

If[FileExistsQ[outputFileName], DeleteFile[outputFileName] ];
Export[outputFileName, allData, "RawJSON", Compact -> True];
Print["saved json data to " <> outputFileName];
