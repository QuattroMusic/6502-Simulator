cbuffer cp_per_object {
	float4x4 camera_data;
}

struct Vertex_Out {
	float4 pos:  SV_POSITION;
	float2 size: SIZE;
	float  col:  COLOR;
};

struct Geom_Output {
    float4 pos: SV_POSITION;
	float  col: COLOR;
	float2 uv:  UVS;
};

Vertex_Out VShader(float4 pos: POSITION, float2 size: SIZE, float color: COLOR) {
	Vertex_Out output;

	output.pos = mul(pos + float4(0, 0, 1, 0), camera_data);

	output.size.x = size.x * camera_data[0][0];
	output.size.y = size.y * camera_data[1][1];

	output.col = color;

    return output;
}

[maxvertexcount(4)]
void GShader(point Vertex_Out input[1], inout TriangleStream<Geom_Output> triStream) {
	Vertex_Out inp = input[0];

	Geom_Output output;
	output.col = inp.col;

	output.pos = inp.pos;
	output.uv = float2(0, 1);
	triStream.Append(output);

	output.pos = inp.pos + float4(0, inp.size.y, 0, 0);
	output.uv = float2(0, 0);
	triStream.Append(output);

	output.pos = inp.pos + float4(inp.size.x, 0, 0, 0);
	output.uv = float2(1, 1);
	triStream.Append(output);

	output.pos = inp.pos + float4(inp.size.x, inp.size.y, 0, 0);
	output.uv = float2(1, 0);
	triStream.Append(output);
}

float4 PShader(Geom_Output input) : SV_TARGET {
	float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	float3 p = abs(frac(input.col + K.xyz) * 6.0 - K.www);
	float3 res = input.uv.y * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), input.uv.x);

    return float4(res, 1.0);
}
