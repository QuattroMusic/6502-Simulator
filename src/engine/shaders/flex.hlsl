cbuffer cp_per_object {
	float4x4 camera_data;
}

struct Vertex_Out {
	float4 pos:  SV_POSITION;
	float2 size: SIZE;
	uint   c1:   TL_COL;
	uint   c2:   TR_COL;
	uint   c3:   BL_COL;
	uint   c4:   BR_COL;
};

struct Geom_Output {
    float4 pos: SV_POSITION;
	float4 col: COLOR;
};

float4 get_color(uint color) {
	float4 col;
	col.x = ( color        & 0xFF) / 255.0f;
	col.y = ((color >> 8 ) & 0xFF) / 255.0f;
	col.z = ((color >> 16) & 0xFF) / 255.0f;
	col.w = ((color >> 24)       ) / 255.0f;
	return col;
}

Vertex_Out VShader(float3 pos: POSITION, float2 size: SIZE, uint c1: TL_COL, uint c2: TR_COL, uint c3: BL_COL, uint c4: BR_COL) {
	Vertex_Out output;

	output.pos = mul(float4(pos, 1), camera_data);

	output.size.x = size.x * camera_data[0][0];
	output.size.y = size.y * camera_data[1][1];

	output.c1 = c1;
	output.c2 = c2;
	output.c3 = c3;
	output.c4 = c4;

    return output;
}

[maxvertexcount(4)]
void GShader(point Vertex_Out input[1], inout TriangleStream<Geom_Output> triStream) {
	Vertex_Out inp = input[0];

	Geom_Output output;

	output.pos = inp.pos;
	output.col = get_color(inp.c1);
	triStream.Append(output);

	output.pos = inp.pos + float4(0, inp.size.y, 0, 0);
	output.col = get_color(inp.c3);
	triStream.Append(output);

	output.pos = inp.pos + float4(inp.size.x, 0, 0, 0);
	output.col = get_color(inp.c2);
	triStream.Append(output);

	output.pos = inp.pos + float4(inp.size.x, inp.size.y, 0, 0);
	output.col = get_color(inp.c4);
	triStream.Append(output);
}

float4 PShader(Geom_Output input) : SV_TARGET {
	return input.col;
}
