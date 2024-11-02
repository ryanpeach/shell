-- Helper function to generate a random character based on input and preserve the case
local function get_random_character(char)
    if char:match('%a') then
        if char:match('%u') then
            -- Replace with a random uppercase letter
            return string.char(math.random(65, 90)) -- ASCII range for 'A'-'Z'
        elseif char:match('%l') then
            -- Replace with a random lowercase letter
            return string.char(math.random(97, 122)) -- ASCII range for 'a'-'z'
        end
    elseif char:match('%d') then
        -- Replace with a random digit (0-9)
        return tostring(math.random(0, 9))
    else
        -- Keep non-alphanumeric characters unchanged
        return char
    end
end

-- Function to replace characters with random characters within a motion range
-- Used to obfuscate text
function _G.replace_with_random_motion(type)
    local start_pos = vim.fn.getpos("'[")
    local end_pos = vim.fn.getpos("']")

    local start_line = start_pos[2]
    local start_col = start_pos[3]
    local end_line = end_pos[2]
    local end_col = end_pos[3]

    if type == "block" then
        -- Handle block-wise selection
        for line_num = start_line, end_line do
            local line = vim.fn.getline(line_num)
            local s_col = start_col
            local e_col = end_col - 1 -- Adjusting for Lua's 1-based indexing

            -- Ensure we don't exceed the line length
            s_col = math.min(s_col, #line + 1)
            e_col = math.min(e_col, #line)

            local new_line = line:sub(1, s_col - 1)
            for col = s_col, e_col do
                local current_char = line:sub(col, col)
                new_line = new_line .. get_random_character(current_char)
            end
            new_line = new_line .. line:sub(e_col + 1)
            vim.fn.setline(line_num, new_line)
        end
    else
        if type == "line" then
            start_col = 1
            end_col = math.huge -- Use a large number to cover the entire line
        end

        for line_num = start_line, end_line do
            local line = vim.fn.getline(line_num)
            local s_col = (line_num == start_line) and start_col or 1
            local e_col = (line_num == end_line) and end_col - 1 or #line

            -- Ensure end column does not exceed line length
            e_col = math.min(e_col, #line)

            local new_line = line:sub(1, s_col - 1)
            for col = s_col, e_col do
                local current_char = line:sub(col, col)
                new_line = new_line .. get_random_character(current_char)
            end
            new_line = new_line .. line:sub(e_col + 1)
            vim.fn.setline(line_num, new_line)
        end
    end
end

-- Register functions globally for operator usage
_G.replace_with_random_motion = replace_with_random_motion

-- Set up which-key mappings
local wk = require("which-key")
wk.add({
    {
        "gRr",
        ":set opfunc=v:lua.replace_with_random_motion<CR>g@",
        desc = "Replace with Random Character"
    }
})
