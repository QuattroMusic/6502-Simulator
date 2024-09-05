init_rendering :: () {
	init_d3d();
	init_shaders();
	init_font();
	init_graphics();
}

deinit_rendering :: () {
	release_buffer :: (buff: Buffer_Data) {
		IUnknown_Release(buff.layout);
		IUnknown_Release(buff.VS);
		IUnknown_Release(buff.PS);
		IUnknown_Release(buff.VBuffer);
		IUnknown_Release(buff.IBuffer);
	}
	
	release_buffer(quad_buffer);
	release_buffer(font_buffer);

	IUnknown_Release(camera_buffer);

	IUnknown_Release(rasterizer);

	IUnknown_Release(swapchain);
	IUnknown_Release(back_buffer);
	IUnknown_Release(dev);
	IUnknown_Release(devcon);
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

	D3D11CreateDeviceAndSwapChain(null,
								  .HARDWARE,
								  null, 0, null, 0,
								  D3D11_SDK_VERSION,
								  *swapchain_desc,
								  *swapchain,
								  *dev,
								  null,
								  *devcon);

	set_render_target();
	set_viewport();
}

init_shaders :: () {
	VS, vertex_error, vertex_res :: #run D3DCompile(quad_shader, "basic", .[], null, "VShader", "vs_5_0", 0, 0);
	PS, pixel_error,  pixel_res  :: #run D3DCompile(quad_shader, "basic", .[], null, "PShader", "ps_5_0", 0, 0);

	#if vertex_res then log_error("[%]: %\n", vertex_res, vertex_error);
	#if pixel_res  then log_error("[%]: %\n", pixel_res,  pixel_error);

	ID3D11Device_CreateVertexShader(dev, VS.data, xx VS.count, null, *quad_buffer.VS);
	ID3D11Device_CreatePixelShader( dev, PS.data, xx PS.count, null, *quad_buffer.PS);
	
	ied :: D3D11_INPUT_ELEMENT_DESC.[
		.{"POSITION", 0, .R32G32B32_FLOAT, 0, 0, .VERTEX_DATA, 0},
		.{"COLOR", 0, .R32G32B32A32_FLOAT, 0, 12, .VERTEX_DATA, 0}
	];
	ID3D11Device_CreateInputLayout(dev, ied.data, xx ied.count, VS.data, xx VS.count, *quad_buffer.layout);

	VS2, vertex_error2, vertex_res2 :: #run D3DCompile(texture_shader, "texture", .[], null, "VShader", "vs_5_0", 0, 0);
	PS2, pixel_error2, pixel_res2   :: #run D3DCompile(texture_shader, "texture", .[], null, "PShader", "ps_5_0", 0, 0);

	#if vertex_res2 then log_error("[%]: %\n", vertex_res2, vertex_error2);
	#if pixel_res2  then log_error("[%]: %\n", pixel_res2, pixel_error2);

	ID3D11Device_CreateVertexShader(dev, VS2.data, xx VS2.count, null, *font_buffer.VS);
	ID3D11Device_CreatePixelShader( dev, PS2.data, xx PS2.count, null, *font_buffer.PS);
	ied2 :: D3D11_INPUT_ELEMENT_DESC.[
		.{"POSITION", 0, .R32G32B32_FLOAT, 0, 0, .VERTEX_DATA, 0},
		.{"COLOR", 0, .R32G32B32A32_FLOAT, 0, 12, .VERTEX_DATA, 0},
		.{"TEXCOORD", 0, .R32G32_FLOAT, 0, 28, .VERTEX_DATA, 0}
	];
	ID3D11Device_CreateInputLayout(dev, ied2.data, ied2.count, VS2.data, xx VS2.count, *font_buffer.layout);
}

init_font :: () {
	texture_data = stbi_load_from_memory(texture_data_file.data, texture_data_file.count, *texture_width, *texture_height, *texture_channels, 0);
	assert(texture_data != null);
	
	desc: D3D11_TEXTURE2D_DESC;
	desc.Width  = xx texture_width;
	desc.Height = xx texture_height;
	desc.MipLevels = 1;
	desc.ArraySize = 1;
	desc.Format = .R8G8B8A8_UNORM;
	desc.SampleDesc.Count = 1;
	desc.Usage = .IMMUTABLE;
	desc.BindFlags = .SHADER_RESOURCE;
	
	init_data: D3D11_SUBRESOURCE_DATA;
	init_data.pSysMem = texture_data;
	init_data.SysMemPitch = xx ((texture_width * 32 + 7) / 8);
	init_data.SysMemSlicePitch = xx ((cast(u32)init_data.SysMemPitch) * cast(u32)texture_height);
	
	ID3D11Device_CreateTexture2D(dev, *desc, *init_data, *texture);
	
	SRVDesc: D3D11_SHADER_RESOURCE_VIEW_DESC;
	SRVDesc.Format = .DXGI_FORMAT_R8G8B8A8_UNORM;
	SRVDesc.ViewDimension = .D3D11_SRV_DIMENSION_TEXTURE2D;
	SRVDesc.Texture2D.MipLevels = 1;
	ID3D11Device_CreateShaderResourceView(dev, texture, *SRVDesc, *texture_resource_view);
	
	sampler_desc: D3D11_SAMPLER_DESC;
	sampler_desc.Filter = .MIN_MAG_MIP_POINT;
	sampler_desc.AddressU = .D3D11_TEXTURE_ADDRESS_WRAP;
	sampler_desc.AddressV = .D3D11_TEXTURE_ADDRESS_WRAP;
	sampler_desc.AddressW = .D3D11_TEXTURE_ADDRESS_WRAP;
	sampler_desc.ComparisonFunc = .D3D11_COMPARISON_NEVER;
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
	ID3D11Device_CreateRasterizerState(dev, *rasterizer_desc, *rasterizer);

	ID3D11DeviceContext_RSSetState(devcon, rasterizer);

	rtbd: D3D11_RENDER_TARGET_BLEND_DESC;
	rtbd.BlendEnable            = xx true;
	rtbd.SrcBlend               = .D3D11_BLEND_SRC_COLOR;
	rtbd.DestBlend              = .D3D11_BLEND_BLEND_FACTOR;
	rtbd.BlendOp                = .D3D11_BLEND_OP_ADD;
	rtbd.SrcBlendAlpha          = .D3D11_BLEND_ONE;
	rtbd.DestBlendAlpha         = .D3D11_BLEND_ZERO;
	rtbd.BlendOpAlpha           = .D3D11_BLEND_OP_ADD;
	rtbd.RenderTargetWriteMask  = xx (D3D11_COLOR_WRITE_ENABLE.ALL);

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
	viewport.Width  = xx vp.width;
	viewport.Height = xx vp.height;

	ID3D11DeviceContext_RSSetViewports(devcon, 1, *viewport);
}

finalize_drawing :: () {
	draw_buffer :: (data: *Buffer_Data) {
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
	
    ID3D11DeviceContext_OMSetBlendState(devcon, null, null, 0xFFFFFFFF);
	draw_buffer(*quad_buffer);

    ID3D11DeviceContext_OMSetBlendState(devcon, transparency, null, 0xFFFFFFFF);
	draw_buffer(*font_buffer);
	
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
	camera = orthographic_projection_matrix(0, xx vp.width, xx vp.height, 0, 1, 1000);
	ID3D11DeviceContext_UpdateSubresource(devcon, camera_buffer, 0, null, *camera, 0, 0);
	ID3D11DeviceContext_VSSetConstantBuffers(devcon, 0, 1, *camera_buffer);
}

clear_background :: (col: Col) {
	ID3D11DeviceContext_ClearRenderTargetView(devcon, back_buffer, *col.component);
}

resize_viewport :: () {
	ID3D11DeviceContext_OMSetRenderTargets(devcon, 0, null, null);
	IUnknown_Release(back_buffer);
	IDXGISwapChain_ResizeBuffers(swapchain, 0, 0, 0, .DXGI_FORMAT_UNKNOWN, 0);

	set_render_target();
	set_viewport();
	update_camera();
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
	x, y, z: float;
	col: [4] float;
}

Tex_Vertex :: struct {
	x, y, z: float;
	col: [4] float;
	uv: [2] float;
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

texture_data_file :: #run read_entire_file("src/joystick monospace.png");

texture_data: *u8;
texture_width, texture_height, texture_channels: s32;

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

    output.position = mul(position, camera_data);
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

struct VS_OUTPUT
{
	float4 Pos : SV_POSITION;
	float4 Color: COLOR;
	float2 TexCoord : TEXCOORD;
};

VS_OUTPUT VShader(float4 inPos : POSITION, float4 inCol : COLOR, float2 inTexCoord : TEXCOORD) {
    VS_OUTPUT output;

    output.Pos = mul(inPos, camera_data);
	output.Color = inCol;
    output.TexCoord = inTexCoord;
	
    return output;
}

float4 PShader(VS_OUTPUT input) : SV_TARGET
{
    return ObjTexture.Sample( ObjSamplerState, input.TexCoord ) * input.Color;
}
DONE
