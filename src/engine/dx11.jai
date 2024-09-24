init_rendering :: () {
	init_d3d();
	init_shaders();
	init_font();
	init_graphics();
	reset_drawing_area();
}

deinit_rendering :: () {
	release_buffer :: (buff: Buffer_Data) {
		if buff.layout  then IUnknown_Release(buff.layout);
		if buff.VS      then IUnknown_Release(buff.VS);
		if buff.PS      then IUnknown_Release(buff.PS);
		if buff.VBuffer then IUnknown_Release(buff.VBuffer);
		if buff.IBuffer then IUnknown_Release(buff.IBuffer);
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
	VS, vertex_error, vertex_res :: #run D3DCompile(quad_shader, "basic", .[], null, "VShader", "vs_5_0", 0, 0);
	PS, pixel_error,  pixel_res  :: #run D3DCompile(quad_shader, "basic", .[], null, "PShader", "ps_5_0", 0, 0);

	#if vertex_res then log_error("[%]: %\n", vertex_res, vertex_error);
	#if pixel_res  then log_error("[%]: %\n", pixel_res,  pixel_error);

	ID3D11Device_CreateVertexShader(dev, VS.data, xx VS.count, null, *quad_buffer.VS);
	ID3D11Device_CreatePixelShader( dev, PS.data, xx PS.count, null, *quad_buffer.PS);

	ied :: D3D11_INPUT_ELEMENT_DESC.[
		.{"POSITION", 0, .R32G32B32_FLOAT,    0,  0, .VERTEX_DATA, 0},
		.{"COLOR",    0, .R32G32B32A32_FLOAT, 0, 12, .VERTEX_DATA, 0}
	];
	ID3D11Device_CreateInputLayout(dev, ied.data, xx ied.count, VS.data, xx VS.count, *quad_buffer.layout);

	VS2, vertex_error2, vertex_res2 :: #run D3DCompile(texture_shader, "texture", .[], null, "VShader", "vs_5_0", 0, 0);
	PS2, pixel_error2, pixel_res2   :: #run D3DCompile(texture_shader, "texture", .[], null, "PShader", "ps_5_0", 0, 0);

	#if vertex_res2 then log_error("[%]: %\n", vertex_res2, vertex_error2);
	#if pixel_res2  then log_error("[%]: %\n", pixel_res2, pixel_error2);

	ID3D11Device_CreateVertexShader(dev, VS2.data, xx VS2.count, null, *font_buffer.VS);
	ID3D11Device_CreatePixelShader( dev, PS2.data, xx PS2.count, null, *font_buffer.PS);
	ied2 :: D3D11_INPUT_ELEMENT_DESC.[
		.{"POSITION", 0, .R32G32B32_FLOAT,    0,  0, .VERTEX_DATA, 0},
		.{"COLOR",    0, .R32G32B32A32_FLOAT, 0, 12, .VERTEX_DATA, 0},
		.{"TEXCOORD", 0, .R32G32_FLOAT,       0, 28, .VERTEX_DATA, 0}
	];
	ID3D11Device_CreateInputLayout(dev, ied2.data, ied2.count, VS2.data, xx VS2.count, *font_buffer.layout);
}

init_font :: () {
	mem := cast(*u8)alloc(texture_width * texture_height * texture_channels,, temp);

	off: int;
	for texture_data {
		v := it;
		for 0..63 {
			x := ifx (v >> (63 - it)) & 1 then 255 else 0;

			mem[it * 4     + off] = xx x;
			mem[it * 4 + 1 + off] = xx x;
			mem[it * 4 + 2 + off] = xx x;
			mem[it * 4 + 3 + off] = xx x;
		}
		off += 64 * 4;
	}

	desc: D3D11_TEXTURE2D_DESC;
	desc.Width            = xx texture_width;
	desc.Height           = xx texture_height;
	desc.MipLevels        = 1;
	desc.ArraySize        = 1;
	desc.Format           = .R8G8B8A8_UNORM;
	desc.SampleDesc.Count = 1;
	desc.Usage            = .IMMUTABLE;
	desc.BindFlags        = .SHADER_RESOURCE;

	init_data: D3D11_SUBRESOURCE_DATA;
	init_data.pSysMem = mem;
	init_data.SysMemPitch = xx (texture_width * 4);
	init_data.SysMemSlicePitch = xx ((cast(u32)init_data.SysMemPitch) * cast(u32)texture_height);

	ID3D11Device_CreateTexture2D(dev, *desc, *init_data, *texture);

	SRVDesc: D3D11_SHADER_RESOURCE_VIEW_DESC;
	SRVDesc.Format = .R8G8B8A8_UNORM;
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

	quad_buffer.vertices_data = alloc(size_of(quad_buffer.vertex_type) * quad_buffer.vertices_allocated);
	quad_buffer.indices_data  = alloc(size_of(u32)                     * quad_buffer.indices_allocated);
	font_buffer.vertices_data = alloc(size_of(font_buffer.vertex_type) * font_buffer.vertices_allocated);
	font_buffer.indices_data  = alloc(size_of(u32)                     * font_buffer.indices_allocated);

	create_vertices_buffer_dx11(*quad_buffer);
	create_indices_buffer_dx11(*quad_buffer);
	create_vertices_buffer_dx11(*font_buffer);
	create_indices_buffer_dx11(*font_buffer);

	ID3D11DeviceContext_IASetPrimitiveTopology(devcon, .TRIANGLELIST);

	rasterizer_desc: D3D11_RASTERIZER_DESC;
	rasterizer_desc.FillMode = .SOLID;
	rasterizer_desc.CullMode = .FRONT;
	rasterizer_desc.ScissorEnable = xx true;
	ID3D11Device_CreateRasterizerState(dev, *rasterizer_desc, *rasterizer);

	ID3D11DeviceContext_RSSetState(devcon, rasterizer);

	rtbd: D3D11_RENDER_TARGET_BLEND_DESC;
	rtbd.BlendEnable            =  xx true;
	rtbd.SrcBlend               = .SRC_ALPHA;
	rtbd.DestBlend              = .INV_SRC_ALPHA;
	rtbd.BlendOp                = .ADD;
	rtbd.SrcBlendAlpha          = .ONE;
	rtbd.BlendOpAlpha           = .ADD;
	rtbd.DestBlendAlpha         = .ZERO;
	rtbd.RenderTargetWriteMask  =  xx D3D11_COLOR_WRITE_ENABLE.ALL;

	blend_desc: D3D11_BLEND_DESC;
	blend_desc.AlphaToCoverageEnable = xx false;
	blend_desc.RenderTarget[0] = rtbd;

	ID3D11Device_CreateBlendState(dev, *blend_desc, *transparency);

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

draw_buffer :: (data: *Buffer_Data) {
	if data.indices_count == 0 then return;

	ID3D11DeviceContext_VSSetShader(devcon, data.VS, null, 0);
	ID3D11DeviceContext_PSSetShader(devcon, data.PS, null, 0);

	ID3D11DeviceContext_IASetInputLayout(devcon, data.layout);

	size :: size_of(data.vertex_type);

	stride: u32 = size;
	offset: u32 = 0;
	ID3D11DeviceContext_IASetVertexBuffers(devcon, 0, 1, *data.VBuffer, *stride, *offset);
	ID3D11DeviceContext_IASetIndexBuffer(devcon, data.IBuffer, .R32_UINT, 0);

	// Todo - something more performant?
	ms: D3D11_MAPPED_SUBRESOURCE;
	ID3D11DeviceContext_Map(devcon, data.VBuffer, 0, .WRITE_DISCARD, 0, *ms);
	memcpy(ms.pData, data.vertices_data, size * data.vertices_count);
	ID3D11DeviceContext_Unmap(devcon, data.VBuffer, 0);

	ID3D11DeviceContext_Map(devcon, data.IBuffer, 0, .WRITE_DISCARD, 0, *ms);
	memcpy(ms.pData, data.indices_data, size_of(u32) * data.indices_count);
	ID3D11DeviceContext_Unmap(devcon, data.IBuffer, 0);

	ID3D11DeviceContext_DrawIndexed(devcon, data.indices_count, 0, 0);

	data.indices_count = 0;
	data.vertices_count = 0;
}

flush_buffers :: () {
    ID3D11DeviceContext_OMSetBlendState(devcon, null, null, 0xFFFFFFFF);
	draw_buffer(*quad_buffer);

    ID3D11DeviceContext_OMSetBlendState(devcon, transparency, null, 0xFFFFFFFF);
	draw_buffer(*font_buffer);
}

finalize_drawing :: () {
	flush_buffers();
	IDXGISwapChain_Present(swapchain, 0, 0);
}

vertices_add :: (using buff: *Buffer_Data, val: buff.vertex_type) {
	if vertices_count == vertices_allocated then resize_vertices(buff, vertices_allocated * 2);
	vertices_data[vertices_count] = val;

	vertices_count += 1;
}

indices_add :: (using buff: *Buffer_Data, val: u32) {
	if indices_count == indices_allocated then resize_indices(buff, indices_allocated * 2);
	indices_data[indices_count] = val;

	indices_count += 1;
}

resize_vertices :: (using buff: *Buffer_Data, new_amt: u32) {
	size :: size_of(buff.vertex_type);

	vertices_data = realloc(vertices_data, new_amt * size, vertices_allocated * size);
	vertices_allocated = new_amt;

	IUnknown_Release(VBuffer);
	create_vertices_buffer_dx11(buff);
}

resize_indices :: (using buff: *Buffer_Data, new_amt: u32) {
	indices_data = realloc(indices_data, new_amt * size_of(u32), indices_allocated * size_of(u32));
	indices_allocated = new_amt;

	IUnknown_Release(IBuffer);
	create_indices_buffer_dx11(buff);
}

create_vertices_buffer_dx11 :: (using buff: *Buffer_Data) {
	vert_buff_desc: D3D11_BUFFER_DESC;
	vert_buff_desc.Usage          = .DYNAMIC;
	vert_buff_desc.ByteWidth      = size_of(buff.vertex_type) * vertices_allocated;
	vert_buff_desc.BindFlags      = .VERTEX_BUFFER;
	vert_buff_desc.CPUAccessFlags = .WRITE;
	ID3D11Device_CreateBuffer(dev, *vert_buff_desc, null, *VBuffer);
}

create_indices_buffer_dx11 :: (using buff: *Buffer_Data) {
	idx_buff_desc: D3D11_BUFFER_DESC;
	idx_buff_desc.Usage          = .DYNAMIC;
	idx_buff_desc.ByteWidth      = size_of(u32) * indices_allocated;
	idx_buff_desc.BindFlags      = .INDEX_BUFFER;
	idx_buff_desc.CPUAccessFlags = .WRITE;
	ID3D11Device_CreateBuffer(dev, *idx_buff_desc, null, *IBuffer);
}

update_camera :: () {
	camera = orthographic_projection_matrix(0, xx vp.width, xx vp.height, 0, 1, 1000, depth_range_01 = true);
	camera._34 = 1;
	ID3D11DeviceContext_UpdateSubresource(devcon, camera_buffer, 0, null, *camera, 0, 0);
	ID3D11DeviceContext_VSSetConstantBuffers(devcon, 0, 1, *camera_buffer);
}

clear_background :: (col: Col) {
	ID3D11DeviceContext_ClearRenderTargetView(devcon, back_buffer, *col.component);
}

set_drawing_area :: (pos: Vec2, size: Vec2) {
	flush_buffers();

	r: RECT;
	r.left = xx pos.x;
	r.top = xx pos.y;
	r.right = xx (pos.x + size.x);
	r.bottom = xx (pos.y + size.y);

	ID3D11DeviceContext_RSSetScissorRects(devcon, 1, *r);
}

reset_drawing_area :: () {
	flush_buffers();

	r: RECT;
	r.left = 0;
	r.right = 0;
	r.right = xx vp.width;
	r.bottom = xx vp.height;

	ID3D11DeviceContext_RSSetScissorRects(devcon, 1, *r);
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
Buffer_Data :: struct (vertex_type: $T) {
	vertices_data: *vertex_type;
	indices_data: *u32;
	vertices_allocated: u32 = 8;
	indices_allocated:  u32 = 8;
	vertices_count:     u32 = 0;
	indices_count:      u32 = 0;

	VS: *ID3D11VertexShader;
	PS: *ID3D11PixelShader;

	VBuffer: *ID3D11Buffer;
	IBuffer: *ID3D11Buffer;

	layout: *ID3D11InputLayout;
}

quad_buffer: Buffer_Data(Vertex);
font_buffer: Buffer_Data(Tex_Vertex);

Vertex :: struct {
	x, y, z: f32;
	col: [4] f32;
}

Tex_Vertex :: struct {
	x, y, z: f32;
	col: [4] f32;
	uv: [2] f32;
}

camera: Matrix4;

swapchain:  *IDXGISwapChain;
dev:        *ID3D11Device;
devcon:     *ID3D11DeviceContext;
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
	0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,
	0x38fc3cf8fefe3ec6, 0x7e06c6c0c6c67cfc, 0x7cfc787ec6c6c6c6, 0x66fe_788078100060,
	0x6cc666ccc0c060c6, 0x1806ccc0eee6c6c6, 0xc6c6cc18c6c6c6ee, 0x660e_604018280020,
	0xc6c6c0c6c0c0c0c6, 0x1806d8c0fef6c6c6, 0xc6c6c018c6c6d67c, 0x661c_602018440030,
	0xc6fcc0c6fcfccefe, 0x1806f0c0fefec6c6, 0xc6ce7c18c6eefe38, 0x3c38_601018000000,
	0xfec6c0c6c0c0c6c6, 0x1806f8c0d6dec6fc, 0xdef80618c67cfe7c, 0x1870_600818000000,
	0xc6c666ccc0c066c6, 0x18c6dcc0c6cec6c0, 0xccdcc618c638eeee, 0x18e0_600418000000,
	0xc6fc3cf8fec03ec6, 0x7e7ccefec6c67cc0, 0x7ace7c187c10c6c6, 0x18fe_780278007e00,

	0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,
	0x1c6c001000203030, 0x60000000000002_38, 0x187c7e1cfc3cfe78, 0x7c_00600c00603838,
	0x1c6c283cc4503060, 0x30281000000004_4c, 0x38c60c3cc060c6c4, 0xc6_60601800304c44,
	0x38247c60c8501060, 0x30101000000008_c6, 0x180e186cfcc00ce4, 0xc6_6000307e180c4c,
	0x3048283810202060, 0x307c7c607c0010_c6, 0x183c3ccc06fc1878, 0x7e_006060000c1854,
	0x20007c0c20540060, 0x30101060000020_c6, 0x187806fe06c6309e, 0x06_6060307e18105c,
	0x000028784cc80060, 0x30281020006040_64, 0x18e0c60cc6c63086, 0x0c_60201800300042,
	0x800000108c740030, 0x60000040006080_38, 0x7efe7c0c7c7c307c, 0x78_00400c0060103c,

	0x0000000000000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000,
	0x387010003c000000, 0x003e7e4200000000, 0x0000000000000000, 0x0000000000000000,
	0x6018100024000000, 0x007e422400000000, 0x0000000000000000, 0x0000000000000000,
	0x6018103224000000, 0x7e46421800000000, 0x0000000000000000, 0x0000000000000000,
	0xe01c104c24000000, 0x7e46421800000000, 0x0000000000000000, 0x0000000000000000,
	0x6018100024000000, 0x0046422400000000, 0x0000000000000000, 0x0000000000000000,
	0x6018100024000000, 0x007c7e4200000000, 0x0000000000000000, 0x0000000000000000,
	0x387010003e000000, 0x0000000000000000, 0x0000000000000000, 0x0000000000000000
];

texture_height   :: #run texture_data.count / 4;
texture_width    :: #run texture_data.count / texture_height * 64;
texture_channels :: 4;  // Todo - is there a way to only have one channel? afterall it's just 0 or 255

#scope_file
quad_shader :: #string DONE
cbuffer cp_per_object {
	float4x4 camera_data;
}

struct VOut {
    float4 position: SV_POSITION;
    float4 color: COLOR;
};

VOut VShader(float4 position: POSITION, float4 color: COLOR) {
    VOut output;

    output.position = mul(position + float4(0, 0, 1, 0), camera_data);
    output.color    = color;

    return output;
}

float4 PShader(float4 position: SV_POSITION, float4 color: COLOR) : SV_TARGET {
    return color;
}
DONE

texture_shader :: #string DONE
Texture2D ObjTexture;
SamplerState ObjSamplerState;

cbuffer cp_per_object {
	float4x4 camera_data;
}

struct VS_OUTPUT {
	float4 Pos : SV_POSITION;
	float4 Color: COLOR;
	float2 TexCoord : TEXCOORD;
};

VS_OUTPUT VShader(float4 inPos : POSITION, float4 inCol : COLOR, float2 inTexCoord : TEXCOORD) {
    VS_OUTPUT output;

    output.Pos = mul(inPos + float4(0, 0, 1, 0), camera_data);
	output.Color = inCol;
    output.TexCoord = inTexCoord;

    return output;
}

float4 PShader(VS_OUTPUT input) : SV_TARGET {
	float4 f = ObjTexture.Sample(ObjSamplerState, input.TexCoord);
	return f * input.Color;
}
DONE
