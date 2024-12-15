Texture2D ObjTexture;
SamplerState ObjSamplerState;

cbuffer cp_per_object {
	float4x4 camera_data;
}

struct Vertex_Out {
	float4 pos:  SV_POSITION;
	float2 size: SIZE;
	uint col:    COLOR;
	float tex:   TEX;
};

struct Geom_Output {
    float4 pos: SV_POSITION;
	uint col:   COLOR;
	float2 tex: TEX;
};

Vertex_Out VShader(float3 position: POSITION, uint size: SIZE, uint inCol: COLOR, float in_texcoord: TEX) {
	Vertex_Out output;

	output.pos = mul(float4(position, 0) + float4(0, 0, 1, 1), camera_data);

	output.size.x = size * camera_data[0][0];
	output.size.y = size * camera_data[1][1];

	output.col = inCol;

	output.tex = in_texcoord;

    return output;
}

[maxvertexcount(4)]
void GShader(point Vertex_Out input[1], inout TriangleStream<Geom_Output> triStream) {
	Vertex_Out inp = input[0];

	Geom_Output output;
	output.col = inp.col;

	output.pos = inp.pos;
	output.tex = float2(inp.tex, 0);
	triStream.Append(output);

	output.pos = inp.pos + float4(0, inp.size.y, 0, 0);
	output.tex = float2(inp.tex, 1);
	triStream.Append(output);

	output.pos = inp.pos + float4(inp.size.x, 0, 0, 0);
	output.tex = float2(8.0 / 1024 + inp.tex, 0);
	triStream.Append(output);

	output.pos = inp.pos + float4(inp.size.x, inp.size.y, 0, 0);
	output.tex = float2(8.0 / 1024 + inp.tex, 1);
	triStream.Append(output);
}

float4 PShader(Geom_Output input) : SV_TARGET {
	float alpha = ObjTexture.Sample(ObjSamplerState, input.tex).w;

	float4 col;
	col.x = ( input.col        & 0xFF) / 255.0f;
	col.y = ((input.col >> 8 ) & 0xFF) / 255.0f;
	col.z = ((input.col >> 16) & 0xFF) / 255.0f;

	return float4(col.x, col.y, col.z, alpha);
}
