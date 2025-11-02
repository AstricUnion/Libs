--@name Custom materials
--@name AstricUnion
--@client

local materials = {}

---@class CMaterial
---@field name string
---@field shader string
---@field generate? function() -> isGenerated: boolean
---@field initialize? function(mat: Material) -> nil
---@field isGenerated? boolean
CMaterial = {}
CMaterial.__index = CMaterial


---Create new CMaterial
---@param name string Name of material to identify it
---@param shader string Shader for material
---@return CMaterial
function CMaterial:new(name, shader)
    local obj = setmetatable(
        {
            name = name,
            shader = shader,
            generate = nil,
            initialize = nil,
            isGenerated = false
        },
        CMaterial
    )
    table.insert(materials, obj)
    return obj
end


---Set initializing function
---@param funcr function(mat: Material) -> nil
---@return CMaterial
function CMaterial:setInitialize(func)
    self.initialize = func
    return self
end


---Set generation function. This function will be started in RenderOffscreen
---@param func function(name: string) -> isGenerated: boolean
---@return CMaterial
function CMaterial:setGeneration(func)
    self.generate = func
    return self
end


---Create and initialize material
---@return Material material Created material to use it
function CMaterial:create()
    local mat = material.create(self.shader)
    if !render.renderTargetExists(self.name) then
        render.createRenderTarget(self.name)
    end
    mat:setTextureRenderTarget("$basetexture", self.name)
    if self.initialize then self.initialize(mat) end
    return mat
end


hook.add("RenderOffscreen", "CMaterialsCreate", function()
    for _, mat in ipairs(materials) do
        if mat.isGenerated then continue end
        render.selectRenderTarget(mat.name)
        if mat.generate then
            mat.isGenerated = mat.generate(mat.name)
        end
    end
    render.selectRenderTarget()
end)
