local M = {}

local state = ya.sync(function()
	return cx.active.current.cwd
end)

function M:entry()
	ya.emit("escape", { visual = true })

	local _permit = ya.hide()
	local cwd = state()

	local output, err = M.run_with(cwd)
	if not output then
		return ya.notify({ title = "Yafg", content = tostring(err), timeout = 5, level = "error" })
	end

	local results = M.split_results(cwd, output)
	if #results == 0 then
		return
	end
	local first_url = results[1][1]
	local cha = fs.cha(first_url)
	ya.emit(cha and cha.is_dir and "cd" or "reveal", { Url(first_url) })
	local paths = {}
	for i, result in ipairs(results) do
		paths[i] = ya.quote(tostring(result[1]) .. ":" .. tostring(result[2]) .. ":" .. tostring(result[3]))
	end
	os.execute("hx " .. table.concat(paths, " "))
end

function M.run_with(cwd)
	local cmd_args = [=[
        RG_PREFIX='rg --column --line-number --no-heading --color=always --smart-case'
        PREVIEW='bat --color=always --highlight-line={2} {1}'
        fzf --ansi --disabled --multi \
            --bind "start:reload:${RG_PREFIX} {q}" \
            --bind "change:reload:sleep 0.1; ${RG_PREFIX} {q} || true" \
            --bind "ctrl-t:transform:[[ ! \${FZF_PROMPT} =~ ripgrep ]] &&
                   echo 'rebind(change)+change-prompt(1. ripgrep> )+disable-search+reload:${RG_PREFIX} \{q} || true' ||
                   echo 'unbind(change)+change-prompt(2. fzf> )+enable-search+reload:${RG_PREFIX} \"\" || true'" \
            --color "hl:-1:underline,hl+:-1:underline:reverse" \
            --prompt '1. ripgrep> ' \
            --delimiter : \
            --header 'CTRL-T: Switch between ripgrep/fzf' \
            --preview "${PREVIEW}" \
            --preview-window 'up,60%,~3,+{2}+3/2' \
            --nth '3..'
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

function M.split_results(cwd, output)
	local t = {}
	for line in output:gmatch("[^\r\n]+") do
		local file, row, col = (string.gmatch(line, "(..-):(%d+):(%d+):"))()
		local u = Url(file)
		if u.is_absolute then
			t[#t + 1] = { u, row, col }
		else
			t[#t + 1] = { cwd:join(u), row, col }
		end
	end
	return t
end

return M
