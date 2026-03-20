local M = {}
M.entities = {}

function M.add_entity(entity)
    table.insert(M.entities, entity)
end

function M.update(dt, time, state)
    for _, e in ipairs(M.entities) do
        if e.update then e:update(dt, time, state) end
    end
end

function M.record_compute(cb, state)
    for _, e in ipairs(M.entities) do
        if e.record_compute then e:record_compute(cb, state) end
    end
end

function M.record_draw(cb, pipe_layout, is_wireframe)
    for _, e in ipairs(M.entities) do
        if e.record_draw then e:record_draw(cb, pipe_layout, is_wireframe) end
    end
end

function M.record_debug_draw(cb, debug_pipe, debug_layout)
    for _, e in ipairs(M.entities) do
        if e.record_debug_draw then e:record_debug_draw(cb, debug_pipe, debug_layout) end
    end
end

function M.check_picking()
    for _, e in ipairs(M.entities) do
        if e.check_picking then e:check_picking() end
    end
end

return M
