init_rendering :: () {
	init_d3d();
	init_shaders();
	init_font();
	init_graphics();
}

deinit_rendering :: () {
	release_buffer :: (buff: Buffer_Data) {
		if buff.layout          then IUnknown_Release(buff.layout);
		if buff.VS              then IUnknown_Release(buff.VS);
		if buff.GS              then IUnknown_Release(buff.GS);
		if buff.PS              then IUnknown_Release(buff.PS);
		if buff.elements_buffer then IUnknown_Release(buff.elements_buffer);
	}

	release_buffer(quad_buffer);
	release_buffer(font_buffer);

	if camera_buffer then IUnknown_Release(camera_buffer);

	if rasterizer then IUnknown_Release(rasterizer);

	if depth_stencil_view   then IUnknown_Release(depth_stencil_view);
	if depth_stencil_buffer then IUnknown_Release(depth_stencil_buffer);

	if swapchain   then IUnknown_Release(swapchain);
	if back_buffer then IUnknown_Release(back_buffer);
	if dev         then IUnknown_Release(dev);
	if devcon      then IUnknown_Release(devcon);
}

init_d3d :: () {
	swapchain_desc: DXGI_SWAP_CHAIN_DESC;
	swapchain_desc.BufferCount = 1;
	swapchain_desc.BufferDesc.Format = .R8G8B8A8_UNORM;
	swapchain_desc.BufferDesc.Width  = xx vp.width;
	swapchain_desc.BufferDesc.Height = xx vp.height;
	swapchain_desc.BufferUsage = .RENDER_TARGET_OUTPUT;
	swapchain_desc.OutputWindow = vp.window;
	swapchain_desc.SampleDesc.Count = 4;
	swapchain_desc.Windowed = xx true;

	D3D11CreateDeviceAndSwapChain(null, .HARDWARE, null, 0, null, 0, D3D11_SDK_VERSION, *swapchain_desc, *swapchain, *dev, null, *devcon);

	set_render_target();
	set_viewport();
	create_depth_stencil();
}

create_depth_stencil :: () {
	depth_buffer_desc: D3D11_TEXTURE2D_DESC;
	depth_buffer_desc.Width            = xx vp.width;
	depth_buffer_desc.Height           = xx vp.height;
	depth_buffer_desc.MipLevels        = 1;
	depth_buffer_desc.ArraySize        = 1;
	depth_buffer_desc.Format           = .D32_FLOAT_S8X24_UINT;
	depth_buffer_desc.SampleDesc.Count = 4;
	depth_buffer_desc.Usage            = .DEFAULT;
	depth_buffer_desc.BindFlags        = .DEPTH_STENCIL;

	ID3D11Device_CreateTexture2D(dev, *depth_buffer_desc, null, *depth_stencil_buffer);

	depth_stencil_desc: D3D11_DEPTH_STENCIL_DESC;
	depth_stencil_desc.DepthEnable                  =  xx true;
	depth_stencil_desc.DepthWriteMask               = .ALL;
	depth_stencil_desc.DepthFunc                    = .LESS;
	depth_stencil_desc.StencilEnable                =  xx true;
	depth_stencil_desc.StencilReadMask              =  0xFF;
	depth_stencil_desc.StencilWriteMask             =  0xFF;
	depth_stencil_desc.FrontFace.StencilFailOp      = .KEEP;
	depth_stencil_desc.FrontFace.StencilDepthFailOp = .INCR;
	depth_stencil_desc.FrontFace.StencilPassOp      = .KEEP;
	depth_stencil_desc.FrontFace.StencilFunc        = .ALWAYS;
	depth_stencil_desc.BackFace.StencilFailOp       = .KEEP;
	depth_stencil_desc.BackFace.StencilDepthFailOp  = .DECR;
	depth_stencil_desc.BackFace.StencilPassOp       = .KEEP;
	depth_stencil_desc.BackFace.StencilFunc         = .ALWAYS;

	ID3D11DeviceContext_OMSetDepthStencilState(devcon, depth_stencil_state, 0xFFFFFFFF);

	if depth_stencil_state then IUnknown_Release(depth_stencil_state);
	ID3D11Device_CreateDepthStencilState(dev, *depth_stencil_desc, *depth_stencil_state);

	dsvDesc: D3D11_DEPTH_STENCIL_VIEW_DESC;
	dsvDesc.Format = .DXGI_FORMAT_D32_FLOAT_S8X24_UINT;
	dsvDesc.ViewDimension = .D3D11_DSV_DIMENSION_TEXTURE2DMS;

	if depth_stencil_view then IUnknown_Release(depth_stencil_view);
	ID3D11Device_CreateDepthStencilView(dev, depth_stencil_buffer, *dsvDesc, *depth_stencil_view);
	if depth_stencil_buffer then IUnknown_Release(depth_stencil_buffer);

	ID3D11DeviceContext_OMSetRenderTargets(devcon, 1, *back_buffer, depth_stencil_view);
}

init_shaders :: () {
	//
	VS1, error1, result1 :: #run D3DCompile(quad_shader, "quad", .[], null, "VShader", "vs_5_0", 0, 0);
	GS1                  :: #run D3DCompile(quad_shader, "quad", .[], null, "GShader", "gs_5_0", 0, 0);
	PS1                  :: #run D3DCompile(quad_shader, "quad", .[], null, "PShader", "ps_5_0", 0, 0);

	// just one error check, since all the three components are in the same file
	#if result1 then log_error("[%]: %\n", result1, error1);

	ID3D11Device_CreateVertexShader(  dev, VS1.data, xx VS1.count, null, *quad_buffer.VS);
	ID3D11Device_CreateGeometryShader(dev, GS1.data, xx GS1.count, null, *quad_buffer.GS);
	ID3D11Device_CreatePixelShader(   dev, PS1.data, xx PS1.count, null, *quad_buffer.PS);
	ied1 :: D3D11_INPUT_ELEMENT_DESC.[
		.{"POSITION", 0, .R32G32B32_FLOAT, 0,  0, .VERTEX_DATA, 0},
		.{"SIZE",     0, .R32G32_FLOAT,    0, 12, .VERTEX_DATA, 0},
		.{"COLOR",    0, .R32_UINT,        0, 20, .VERTEX_DATA, 0}
	];
	ID3D11Device_CreateInputLayout(dev, ied1.data, ied1.count, VS1.data, xx VS1.count, *quad_buffer.layout);
	
	//
	fmt :: #run tprint(font_shader, texture_width, texture_height);
	VS2, error2, result2 :: #run D3DCompile(fmt, "font", .[], null, "VShader", "vs_5_0", 0, 0);
	GS2                  :: #run D3DCompile(fmt, "font", .[], null, "GShader", "gs_5_0", 0, 0);
	PS2                  :: #run D3DCompile(fmt, "font", .[], null, "PShader", "ps_5_0", 0, 0);

	#if result2 then log_error("[%]: %\n", result2, error2);

	ID3D11Device_CreateVertexShader(  dev, VS2.data, xx VS2.count, null, *font_buffer.VS);
	ID3D11Device_CreateGeometryShader(dev, GS2.data, xx GS2.count, null, *font_buffer.GS);
	ID3D11Device_CreatePixelShader(   dev, PS2.data, xx PS2.count, null, *font_buffer.PS);
	ied2 :: D3D11_INPUT_ELEMENT_DESC.[
		.{"POSITION", 0, .R32G32B32_FLOAT, 0,  0, .VERTEX_DATA, 0},
		.{"SIZE",     0, .R32_UINT,        0, 12, .VERTEX_DATA, 0},
		.{"COLOR",    0, .R32_UINT,        0, 16, .VERTEX_DATA, 0},
		.{"TEXCOORD", 0, .R32G32_FLOAT,    0, 20, .VERTEX_DATA, 0},
	];
	ID3D11Device_CreateInputLayout(dev, ied2.data, ied2.count, VS2.data, xx VS2.count, *font_buffer.layout);
}

init_font :: () {
	// The font is stored internally as lines of bits. If a bit is 1, there's the pixel, and if not, it's empty
	// so, we should convert the packed data to the format for DX11
	mem: [texture_width * texture_height]u8;

	off: int;
	for texture_data {
		v := it;
		for 0..63 {
			x := ifx (v >> (63 - it)) & 1 then 255;
			mem[it + off] = xx x;
		}
		off += 64;
	}

	desc: D3D11_TEXTURE2D_DESC;
	desc.Width            = xx texture_width;
	desc.Height           = xx texture_height;
	desc.MipLevels        = 1;
	desc.ArraySize        = 1;
	desc.Format           = .A8_UNORM;
	desc.SampleDesc.Count = 1;
	desc.Usage            = .IMMUTABLE;
	desc.BindFlags        = .SHADER_RESOURCE;

	init_data: D3D11_SUBRESOURCE_DATA;
	init_data.pSysMem = mem.data;
	init_data.SysMemPitch = xx texture_width;
	init_data.SysMemSlicePitch = xx (cast(u32)texture_width * cast(u32)texture_height);

	ID3D11Device_CreateTexture2D(dev, *desc, *init_data, *texture);

	SRVDesc: D3D11_SHADER_RESOURCE_VIEW_DESC;
	SRVDesc.Format = desc.Format;
	SRVDesc.ViewDimension = .TEXTURE2D;
	SRVDesc.Texture2D.MipLevels = 1;
	ID3D11Device_CreateShaderResourceView(dev, texture, *SRVDesc, *texture_resource_view);

	sampler_desc: D3D11_SAMPLER_DESC;
	sampler_desc.Filter = .MIN_MAG_MIP_POINT;
	sampler_desc.AddressU = .CLAMP;
	sampler_desc.AddressV = .CLAMP;
	sampler_desc.AddressW = .CLAMP;
	sampler_desc.ComparisonFunc = .NEVER;
	sampler_desc.MinLOD = 0;
	sampler_desc.MaxLOD = FLOAT32_MAX;

	ID3D11Device_CreateSamplerState(dev, *sampler_desc, *tex_sampler_state);

	ID3D11DeviceContext_PSSetShaderResources(devcon, 0, 1, *texture_resource_view);
	ID3D11DeviceContext_PSSetSamplers(devcon, 0, 1, *tex_sampler_state);
}

init_graphics :: () {
	buff_desc: D3D11_BUFFER_DESC;
	buff_desc.Usage = .DEFAULT;
	buff_desc.ByteWidth = size_of(Matrix4);
	buff_desc.BindFlags = .CONSTANT_BUFFER;
	ID3D11Device_CreateBuffer(dev, *buff_desc, null, *camera_buffer);

	quad_buffer.elements_view.data = quad_elements.data;
	font_buffer.elements_view.data = font_elements.data;

	create_elements_buffer_dx11(*quad_buffer, quad_elements.count);
	create_elements_buffer_dx11(*font_buffer, font_elements.count);
	
	ID3D11DeviceContext_IASetPrimitiveTopology(devcon, .POINTLIST);

	rasterizer_desc: D3D11_RASTERIZER_DESC;
	rasterizer_desc.FillMode = .SOLID;
	rasterizer_desc.CullMode = .FRONT;
	ID3D11Device_CreateRasterizerState(dev, *rasterizer_desc, *rasterizer);

	ID3D11DeviceContext_RSSetState(devcon, rasterizer);

	rtbd: D3D11_RENDER_TARGET_BLEND_DESC;
	rtbd.BlendEnable            =  xx false;
	rtbd.RenderTargetWriteMask  =  xx D3D11_COLOR_WRITE_ENABLE.ALL;

	blend_desc: D3D11_BLEND_DESC;
	blend_desc.AlphaToCoverageEnable = xx true;
	blend_desc.RenderTarget[0] = rtbd;

	ID3D11Device_CreateBlendState(dev, *blend_desc, *transparency);

	ID3D11DeviceContext_OMSetBlendState(devcon, transparency, null, 0xFFFFFFFF);

	update_camera();
}

set_render_target :: () {
	temp: *ID3D11Texture2D;
	IDXGISwapChain_GetBuffer(swapchain, 0, *uid(ID3D11Texture2D_UUID), xx *temp);

	ID3D11Device_CreateRenderTargetView(dev, temp, null, *back_buffer);
	IUnknown_Release(temp);

	ID3D11DeviceContext_OMSetRenderTargets(devcon, 1, *back_buffer, null);
}

set_viewport :: () {
	viewport: D3D11_VIEWPORT;
	viewport.TopLeftX = 0;
	viewport.TopLeftY = 0;
	viewport.Width    = xx vp.width;
	viewport.Height   = xx vp.height;
	viewport.MinDepth = 0;
	viewport.MaxDepth = 1;

	ID3D11DeviceContext_RSSetViewports(devcon, 1, *viewport);
}

begin_drawing :: () {
	flags: u32 = xx (D3D11_CLEAR_FLAG.DEPTH | D3D11_CLEAR_FLAG.STENCIL);
	ID3D11DeviceContext_ClearDepthStencilView(devcon, depth_stencil_view, flags, 1, 0);
}

flush_buffer :: (data: *Buffer_Data) {
	if data.elements_view.count == 0 then return;

	ID3D11DeviceContext_VSSetShader(devcon, data.VS, null, 0);
	ID3D11DeviceContext_GSSetShader(devcon, data.GS, null, 0);
	ID3D11DeviceContext_PSSetShader(devcon, data.PS, null, 0);

	ID3D11DeviceContext_IASetInputLayout(devcon, data.layout);

	size :: size_of(data.vertex_type);

	stride: u32 = size;
	offset: u32 = 0;

	ID3D11DeviceContext_IASetVertexBuffers(devcon, 0, 1, *data.elements_buffer, *stride, *offset);

	ms: D3D11_MAPPED_SUBRESOURCE;
	ID3D11DeviceContext_Map(devcon, data.elements_buffer, 0, .WRITE_DISCARD, 0, *ms);
	memcpy(ms.pData, data.elements_view.data, size * data.elements_view.count);
	ID3D11DeviceContext_Unmap(devcon, data.elements_buffer, 0);

	ID3D11DeviceContext_Draw(devcon, xx data.elements_view.count, 0);

	data.elements_view.count = 0;
}

finalize_drawing :: () {
	flush_buffer(*quad_buffer);
	flush_buffer(*font_buffer);
	IDXGISwapChain_Present(swapchain, 0, 0);
}

element_add :: (using buff: *Buffer_Data, val: buff.vertex_type) {
	if elements_view.count == BUFFER_MAX_SIZE then flush_buffer(buff);
	
	#no_abc {
		elements_view[elements_view.count] = val;
		elements_view.count += 1;
	}
}

create_elements_buffer_dx11 :: (using buff: *Buffer_Data, amt: s64) {
	buff_desc: D3D11_BUFFER_DESC;
	buff_desc.Usage          = .DYNAMIC;
	buff_desc.ByteWidth      = xx (size_of(buff.vertex_type) * amt);
	buff_desc.BindFlags      = .VERTEX_BUFFER;
	buff_desc.CPUAccessFlags = .WRITE;
	ID3D11Device_CreateBuffer(dev, *buff_desc, null, *elements_buffer);
}

update_camera :: () {
	camera = orthographic_projection_matrix(0, xx vp.width, xx vp.height, 0, 1, 1000, depth_range_01 = true);
	camera._34 = 1;
	ID3D11DeviceContext_UpdateSubresource(devcon, camera_buffer, 0, null, *camera, 0, 0);
	ID3D11DeviceContext_VSSetConstantBuffers(devcon, 0, 1, *camera_buffer);
}

clear_background :: (col: Col) {
	c: [4]float = .[col.r / 255.0, col.g / 255.0, col.b / 255.0, col.a / 255.0];
	ID3D11DeviceContext_ClearRenderTargetView(devcon, back_buffer, *c);
}

resize_viewport :: () {
	ID3D11DeviceContext_OMSetRenderTargets(devcon, 0, null, null);
	IUnknown_Release(back_buffer);
	IDXGISwapChain_ResizeBuffers(swapchain, 0, 0, 0, .DXGI_FORMAT_UNKNOWN, 0);

	set_render_target();
	set_viewport();
	update_camera();
	create_depth_stencil();
}

#scope_module
Buffer_Data :: struct (vertex_type: Type) {
	elements_view: [] vertex_type;

	VS: *ID3D11VertexShader;
	PS: *ID3D11PixelShader;
	GS: *ID3D11GeometryShader;

	elements_buffer: *ID3D11Buffer;

	layout: *ID3D11InputLayout;
}

BUFFER_MAX_SIZE :: 0xFFF;

quad_elements: [BUFFER_MAX_SIZE] Quad_Vertex;
font_elements: [BUFFER_MAX_SIZE] Font_Vertex;

quad_buffer: Buffer_Data(Quad_Vertex);
font_buffer: Buffer_Data(Font_Vertex);

Font_Vertex :: struct {
	x, y, z: f32;
	s: u32;
	col: u32;
	uv: [2] f32;
}

Quad_Vertex :: struct {
	x, y, z: f32;
	w, h: f32;
	col: u32;
}

camera: Matrix4;

swapchain:   *IDXGISwapChain;
dev:         *ID3D11Device;
devcon:      *ID3D11DeviceContext;
back_buffer: *ID3D11RenderTargetView;

camera_buffer: *ID3D11Buffer;

rasterizer: *ID3D11RasterizerState;

texture: *ID3D11Texture2D;
texture_resource_view: *ID3D11ShaderResourceView;
tex_sampler_state: *ID3D11SamplerState;

transparency: *ID3D11BlendState;

depth_stencil_view: *ID3D11DepthStencilView;
depth_stencil_buffer: *ID3D11Texture2D;
depth_stencil_state: *ID3D11DepthStencilState;

texture_data :: u64.[
	0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000_000000000000,
	0x38fc3cf8fefe3ec6, 0x7e06c6c0c6c67cfc, 0x7cfc787ec6c6c6c6, 0x66fe_788078100060,
	0x6cc666ccc0c060c6, 0x1806ccc0eee6c6c6, 0xc6c6cc18c6c6c6ee, 0x660e_604018280020,
	0xc6c6c0c6c0c0c0c6, 0x1806d8c0fef6c6c6, 0xc6c6c018c6c6d67c, 0x661c_602018440030,
	0xc6fcc0c6fcfccefe, 0x1806f0c0fefec6c6, 0xc6ce7c18c6eefe38, 0x3c38_601018000000,
	0xfec6c0c6c0c0c6c6, 0x1806f8c0d6dec6fc, 0xdef80618c67cfe7c, 0x1870_600818000000,
	0xc6c666ccc0c066c6, 0x18c6dcc0c6cec6c0, 0xccdcc618c638eeee, 0x18e0_600418000000,
	0xc6fc3cf8fec03ec6, 0x7e7ccefec6c67cc0, 0x7ace7c187c10c6c6, 0x18fe_780278007e00,

	0x0000000000000000, 0x00000000000000_00, 0x0000000000000000, 0x00_00000000000000,
	0x1c6c001000203030, 0x60000000000002_38, 0x187c7e1cfc3cfe78, 0x7c_00600c00603838,
	0x1c6c283cc4503060, 0x30281000000004_4c, 0x38c60c3cc060c6c4, 0xc6_60601800304c44,
	0x38247c60c8501060, 0x30101000000008_c6, 0x180e186cfcc00ce4, 0xc6_6000307e180c4c,
	0x3048283810202060, 0x307c7c607c0010_c6, 0x183c3ccc06fc1878, 0x7e_006060000c1854,
	0x20007c0c20540060, 0x30101060000020_c6, 0x187806fe06c6309e, 0x06_6060307e18105c,
	0x000028784cc80060, 0x30281020006040_64, 0x18e0c60cc6c63086, 0x0c_60201800300042,
	0x800000108c740030, 0x60000040006080_38, 0x7efe7c0c7c7c307c, 0x78_00400c0060103c,

	0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,
	0x381070003c000000, 0x003e7e4200000000, 0x0000000000000000, 0x0000000000000000,
	0x6010180024000000, 0x007e422400000000, 0x0000000000000000, 0x0000000000000000,
	0x6010183224000000, 0x7e46421800000000, 0x0000000000000000, 0x0000000000000000,
	0xe0101c4c24000000, 0x7e46421800000000, 0x0000000000000000, 0x0000000000000000,
	0x6010180024000000, 0x0046422400000000, 0x0000000000000000, 0x0000000000000000,
	0x6010180024000000, 0x007c7e4200000000, 0x0000000000000000, 0x0000000000000000,
	0x381070003c000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000
];

texture_height   :: #run texture_data.count / 4;
texture_width    :: #run texture_data.count / texture_height * 64;
texture_channels :: 1;

#scope_file
quad_shader :: #string DONE
cbuffer cp_per_object {
	float4x4 camera_data;
}

struct Vertex_Out {
	float4 pos: SV_POSITION;
	float2 size: SIZE;
	uint col: COLOR;
};

struct Geom_Output {
    float4 pos: SV_POSITION;
	uint col: COLOR;
};

Vertex_Out VShader(float4 pos: POSITION, float2 size: SIZE, uint col: COLOR) {
	Vertex_Out output;
	
	output.pos = mul(pos + float4(0, 0, 1, 0), camera_data);
	
	output.size.x = size.x * camera_data[0][0];
	output.size.y = size.y * camera_data[1][1];
	
	output.col = col;

    return output;
}

[maxvertexcount(4)]
void GShader(point Vertex_Out input[1], inout TriangleStream<Geom_Output> triStream) {
	Vertex_Out inp = input[0];

	Geom_Output output;
	output.col = inp.col;
	
	output.pos = inp.pos;
	triStream.Append(output);
	
	output.pos = inp.pos + float4(0, inp.size.y, 0, 0);
	triStream.Append(output);
	
	output.pos = inp.pos + float4(inp.size.x, 0, 0, 0);
	triStream.Append(output);
	
	output.pos = inp.pos + float4(inp.size.x, inp.size.y, 0, 0);
	triStream.Append(output);
}

float4 PShader(Geom_Output input) : SV_TARGET {
	float4 col;
	col.x = ( input.col        & 0xFF) / 255.0f;
	col.y = ((input.col >> 8 ) & 0xFF) / 255.0f;
	col.z = ((input.col >> 16) & 0xFF) / 255.0f;
	col.w = ((input.col >> 24) & 0xFF) / 255.0f;
    return col;
}
DONE

font_shader :: #string DONE
Texture2D ObjTexture;
SamplerState ObjSamplerState;

cbuffer cp_per_object {
	float4x4 camera_data;
}

struct Vertex_Out {
	float4 pos: SV_POSITION;
	float2 size: SIZE;
	uint color: COLOR;
	float2 TexCoord : TEXCOORD;
};

struct Geom_Output {
    float4 pos: SV_POSITION;
	uint color: COLOR;
	float2 TexCoord : TEXCOORD;
};

// since this file is a string and the texture_[width / height] is calculated at compile time,
// we're formatting the string and then passing it to the shader
#define uv_x_increment (8.0 / %1)
#define uv_y_increment (8.0 / %2)

Vertex_Out VShader(float4 position: POSITION, uint size: SIZE, uint inCol: COLOR, float2 in_texcoord: TEXCOORD) {
	Vertex_Out output;
	
	output.pos = mul(position + float4(0, 0, 1, 0), camera_data);
	
	output.size.x = size * camera_data[0][0];
	output.size.y = size * camera_data[1][1];
	
	output.color = inCol;
	
	output.TexCoord = in_texcoord;

    return output;
}

[maxvertexcount(4)]
void GShader(point Vertex_Out input[1], inout TriangleStream<Geom_Output> triStream) {
	Vertex_Out inp = input[0];
	
	Geom_Output output;
	output.color = inp.color;
	
	output.pos = inp.pos;
	output.TexCoord = inp.TexCoord;
	triStream.Append(output);
	
	output.pos = inp.pos + float4(0, inp.size.y, 0, 0);
	output.TexCoord = inp.TexCoord + float2(0, uv_y_increment);
	triStream.Append(output);
	
	output.pos = inp.pos + float4(inp.size.x, 0, 0, 0);
	output.TexCoord = inp.TexCoord + float2(uv_x_increment, 0);
	triStream.Append(output);
	
	output.pos = inp.pos + float4(inp.size.x, inp.size.y, 0, 0);
	output.TexCoord = inp.TexCoord + float2(uv_x_increment, uv_y_increment);
	triStream.Append(output);
}

float4 PShader(Geom_Output input) : SV_TARGET {
	float alpha = ObjTexture.Sample(ObjSamplerState, input.TexCoord).w;

	float4 col;
	col.x = ( input.color        & 0xFF) / 255.0f;
	col.y = ((input.color >> 8 ) & 0xFF) / 255.0f;
	col.z = ((input.color >> 16) & 0xFF) / 255.0f;

	return float4(col.x, col.y, col.z, alpha);
}
DONE
