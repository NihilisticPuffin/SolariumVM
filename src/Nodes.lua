local function create_node(type, props)
    props = props or {}
    props.type = type
    return setmetatable(props, {
        __tostring = function(self)
            return type
        end
    })
end

return {
    Program      = function(statements) return create_node("Program", { statements = statements }) end,
    FuncDecl     = function(name, params, body) return create_node("FuncDecl", { name = name, params = params, body = body }) end,
    BlockStmt    = function(body) return create_node("BlockStmt", { body = body }) end,
    ExprStmt     = function(expr) return create_node("ExprStmt", { expr = expr }) end,
    VarStmt      = function(name, init) return create_node("VarStmt", { name = name, init = init }) end,
    IfStmt       = function(cond, then_branch, else_branch) return create_node("IfStmt", { cond = cond, ["then"] = then_branch, ["else"] = else_branch }) end,
    WhileStmt    = function(cond, body) return create_node("WhileStmt", { cond = cond, body = body }) end,
    ReturnStmt   = function(value) return create_node("ReturnStmt", { value = value }) end,
    BinaryExpr   = function(left, op, right) return create_node("BinaryExpr", { left = left, op = op, right = right }) end,
    UnaryExpr    = function(op, right) return create_node("UnaryExpr", { op = op, right = right }) end,
    AssignExpr   = function(name, value) return create_node("AssignExpr", { name = name, value = value }) end,
    CallExpr     = function(callee, args) return create_node("CallExpr", { callee = callee, args = args }) end,
    LiteralExpr  = function(value) return create_node("LiteralExpr", { value = value }) end,
    VariableExpr = function(name) return create_node("VariableExpr", { name = name }) end,
}