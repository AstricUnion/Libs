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
---@field material? Material
CMaterial = {}
CMaterial.__index = CMaterial


---Create new invalid CMaterial
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
            isGenerated = false,
            material = nil
        },
        CMaterial
    )
    table.insert(materials, obj)
    return obj
end


---Set initializing function
---@param func function(mat: Material) -> nil
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


---Is custom material valid?
---@return boolean
function CMaterial:isValid()
    return self.material ~= nil
end


---Create and initialize material
---@return Material material Created and valid custom material to use it
function CMaterial:create()
    local mat = material.create(self.shader)
    if !render.renderTargetExists(self.name) then
        render.createRenderTarget(self.name)
    end
    mat:setTextureRenderTarget("$basetexture", self.name)
    if self.initialize then self.initialize(mat) end
    self.material = mat
    return mat
end


hook.add("RenderOffscreen", "CMaterialsCreate", function()
    for _, cmat in ipairs(materials) do
        if cmat.isGenerated then continue end
        render.selectRenderTarget(cmat.name)
        if cmat.generate then
            cmat.isGenerated = cmat.generate(cmat.name)
        end
    end
    render.selectRenderTarget()
end)
