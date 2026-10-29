function Initialize()
    path = SKIN:GetVariable('@') .. 'Today.txt'
end

function Update()
    local file = io.open(path, 'r')

    if not file then
        return 0
    end

    local count = 0

    for line in file:lines() do
        if string.match(line, '^%d%d:%d%d$') then
            count = count + 1
        end
    end

    file:close()

    return count
end