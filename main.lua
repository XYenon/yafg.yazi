local M = {
	toggle_mode_key = "ctrl-t",
	editor = "hx",
	args = {},
	file_arg_format = "{file}:{row}:{col}",
}

local cwd = ya.sync(function()
	return cx.active.current.cwd
end)

local sync_self = ya.sync(function()
	local self = {}
	for key, value in pairs(M) do
		if type(value) ~= "function" then
			self[key] = value
		end
	end
	return self
end)

local function format_key_for_display(key)
	return (key:gsub("[^-]+", function(part)
		return part:sub(1, 1):upper() .. part:sub(2)
	end))
end

function M:setup(opts)
	self.toggle_mode_key = opts.toggle_mode_key or self.toggle_mode_key
	self.editor = opts.editor or self.editor
	self.args = opts.args or self.args
	self.file_arg_format = opts.file_arg_format or self.file_arg_format
end

function M:entry()
	ya.emit("escape", { visual = true })

	local _permit = ui.hide()
	local cwd = cwd()

	local output, err = M.run_with(cwd)
	if not output then
		return ya.notify({ title = "Yafg", content = tostring(err), timeout = 5, level = "error" })
	end

	local results = M.split_results(cwd, output)
	if #results == 0 then
		return
	elseif #results == 1 then
		local first_url = results[1][1]
		local cha = fs.cha(first_url)
		ya.emit(cha and cha.is_dir and "cd" or "reveal", { Url(first_url) })
	end

	local ss = sync_self()
	local args = {}
	for i, arg in ipairs(ss.args) do
		args[i] = ya.quote(arg)
	end
	local file_args = {}
	for i, result in ipairs(results) do
		local quoted_file = ya.quote(tostring(result[1]))
		local arg = string.gsub(ss.file_arg_format, "{file}", function()
			return quoted_file
		end)
		arg = string.gsub(arg, "{row}", tostring(result[2]))
		arg = string.gsub(arg, "{col}", tostring(result[3]))
		file_args[i] = arg
	end

	local cmd = ss.editor .. " " .. table.concat(args, " ") .. " " .. table.concat(file_args, " ")
	ya.dbg("Yafg", "editor cmd", cmd)
	os.execute(cmd)
end

function M.run_with(cwd)
	local ss = sync_self()
	local cmd_args = "TOGGLE_KEY="
		.. ya.quote(ss.toggle_mode_key)
		.. " DISPLAY_TOGGLE_KEY="
		.. ya.quote(format_key_for_display(ss.toggle_mode_key))
		.. [=[
        RG_PREFIX=$'rg --column --line-number --no-heading --color=always --smart-case --field-match-separator \x1f:\x1e'
        PREVIEW='bat --color=always --highlight-line={2} -- {1}'
        fzf --ansi --disabled --multi \
            --bind "start:reload:${RG_PREFIX} {q}" \
            --bind "change:reload:sleep 0.1; ${RG_PREFIX} {q} || true" \
            --bind "${TOGGLE_KEY}:transform:[[ ! \${FZF_PROMPT} =~ ripgrep ]] &&
                   echo 'rebind(change)+change-prompt(1. ripgrep> )+disable-search+reload:${RG_PREFIX} \{q} || true' ||
                   echo 'unbind(change)+change-prompt(2. fzf> )+enable-search+reload:${RG_PREFIX} \"\" || true'" \
            --color "hl:-1:underline,hl+:-1:underline:reverse" \
            --prompt '1. ripgrep> ' \
            --delimiter '\x1f:\x1e' \
            --nth '4..' \
            --header "${DISPLAY_TOGGLE_KEY}: Switch between ripgrep/fzf" \
            --preview "${PREVIEW}" \
            --preview-window 'up,60%,~3,+{2}+3/2'
        ]=]
	local child, err =
		Command("bash"):arg({ "-c", cmd_args }):cwd(tostring(cwd)):stdin(Command.INHERIT):stdout(Command.PIPED):spawn()

	if not child then
		return nil, Err("Failed to start `fzf`, error: %s", err)
	end

	local output, err = child:wait_with_output()
	if not output then
		return nil, Err("Cannot read `fzf` output, error: %s", err)
	elseif not output.status.success and output.status.code ~= 130 then
		return nil, Err("`fzf` exited with error code %s", output.status.code)
	end
	return output.stdout, nil
end

local field_sep = "\31:\30"

function M.split_results(cwd, output)
	local t = {}
	for line in output:gmatch("[^\r\n]+") do
		local file, row, col = line:match("^(.-)" .. field_sep .. "(%d+)" .. field_sep .. "(%d+)" .. field_sep)
		if file then
			local u = Url(file)
			t[#t + 1] = {
				u.is_absolute and u or cwd:join(u),
				row,
				col,
			}
		end
	end
	return t
end

return M
