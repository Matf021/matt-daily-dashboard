local lines = {}
local scrollOffset = 0
local visibleLines = 7

-- Approximate number of Consolas characters that fit
-- inside the Rainmeter notes viewport.
local wrapWidth = 36


function Initialize()
    path = SKIN:GetVariable('@') .. 'Today.txt'
end

local function notesViewIsActive()

    return
        SKIN:GetVariable('CurrentView') == 'Notes'
        and SKIN:GetVariable('WriteMode') ~= '1'
        and SKIN:GetVariable('TaskConfirm') ~= '1'

end

local function refreshNotes()

    SKIN:Bang(
        '!UpdateMeasure',
        'MeasureNotes'
    )

    SKIN:Bang(
        '!UpdateMeter',
        'Notes'
    )

    SKIN:Bang(
        '!UpdateMeter',
        'NotesGlow'
    )

    SKIN:Bang(
        '!UpdateMeter',
        'NotesEmpty'
    )

    SKIN:Bang('!Redraw')

end


-- ==================================================
-- TEXT WRAPPING
-- ==================================================

local function wrapLine(text, width)
    if text == '' then
        return { '' }
    end

    -- Don't wrap timestamp lines
    if string.match(text, '^%d%d:%d%d$') then
        return { text }
    end

    local wrapped = {}
    local current = ''

    for word in string.gmatch(text, '%S+') do

        if current == '' then
            current = word

        elseif #current + #word + 1 <= width then
            current = current .. ' ' .. word

        else
            table.insert(wrapped, current)
            current = word
        end
    end

    if current ~= '' then
        table.insert(wrapped, current)
    end

    return wrapped
end


-- ==================================================
-- LOAD NOTES
-- ==================================================

local function loadLines()

    lines = {}

    local file =
        io.open(
            path,
            'r'
        )

    if not file then
        return
    end

    local rawLines = {}
    local hasContent = false

    for line in file:lines() do

        table.insert(
            rawLines,
            line
        )

        if string.match(line, '%S') then
            hasContent = true
        end

    end

    file:close()

    if not hasContent then
        return
    end

    for _, line in ipairs(rawLines) do

        local wrapped =
            wrapLine(
                line,
                wrapWidth
            )

        for _, wrappedLine in ipairs(wrapped) do

            table.insert(
                lines,
                wrappedLine
            )

        end

    end

end


-- ==================================================
-- SCROLL LIMITS
-- ==================================================

local function getMaxOffset()
    return math.max(0, #lines - visibleLines)
end


local function clampScroll()
    local maxOffset = getMaxOffset()

    if scrollOffset < 0 then
        scrollOffset = 0

    elseif scrollOffset > maxOffset then
        scrollOffset = maxOffset
    end
end


-- ==================================================
-- SCROLLBAR VISIBILITY / ARROWS
-- ==================================================

local function updateScrollButtons()

    local maxOffset =
        getMaxOffset()

    if not notesViewIsActive()
        or maxOffset <= 0 then

            SKIN:Bang('!HideMeter', 'ScrollRail')
            SKIN:Bang('!HideMeter', 'ScrollThumb')
            SKIN:Bang('!HideMeter', 'ScrollThumbGlow')
            SKIN:Bang('!HideMeter', 'ScrollUp')
            SKIN:Bang('!HideMeter', 'ScrollDown')

            return
        end

    -- ==============================================
    -- SHOW SCROLLBAR
    -- ==============================================

    SKIN:Bang('!ShowMeter', 'ScrollRail')
    SKIN:Bang('!ShowMeter', 'ScrollThumb')
    SKIN:Bang('!ShowMeter', 'ScrollThumbGlow')
    SKIN:Bang('!ShowMeter', 'ScrollUp')
    SKIN:Bang('!ShowMeter', 'ScrollDown')


    -- UP arrow
    if scrollOffset <= 0 then

        SKIN:Bang(
            '!SetOption',
            'ScrollUp',
            'Shape',
            'Path UpArrow | Fill Color 40,110,55,100 | StrokeWidth 0'
        )

    else

        SKIN:Bang(
            '!SetOption',
            'ScrollUp',
            'Shape',
            'Path UpArrow | Fill Color 70,180,90,255 | StrokeWidth 0'
        )

    end


    -- DOWN arrow
    if scrollOffset >= maxOffset then

        SKIN:Bang(
            '!SetOption',
            'ScrollDown',
            'Shape',
            'Path DownArrow | Fill Color 40,110,55,100 | StrokeWidth 0'
        )

    else

        SKIN:Bang(
            '!SetOption',
            'ScrollDown',
            'Shape',
            'Path DownArrow | Fill Color 70,180,90,255 | StrokeWidth 0'
        )

    end


    SKIN:Bang('!UpdateMeter', 'ScrollRail')
    SKIN:Bang('!UpdateMeter', 'ScrollThumb')
    SKIN:Bang('!UpdateMeter', 'ScrollThumbGlow')
    SKIN:Bang('!UpdateMeter', 'ScrollUp')
    SKIN:Bang('!UpdateMeter', 'ScrollDown')

end


-- ==================================================
-- SCROLL THUMB
-- ==================================================

local function updateScrollThumb()
    local maxOffset = getMaxOffset()

    local topY = 80
    local bottomY = 160
    local travel = bottomY - topY

    local y = topY

    if maxOffset > 0 then
        y = topY + math.floor(
            (scrollOffset / maxOffset) * travel
        )
    end

    SKIN:Bang(
        '!SetOption',
        'ScrollThumb',
        'Y',
        tostring(y)
    )

    SKIN:Bang(
        '!SetOption',
        'ScrollThumbGlow',
        'Y',
        tostring(y - 1)
    )

    SKIN:Bang('!UpdateMeter', 'ScrollThumb')
    SKIN:Bang('!UpdateMeter', 'ScrollThumbGlow')
end


-- ==================================================
-- UPDATE
-- ==================================================

function Update()

    if not notesViewIsActive() then

        SKIN:Bang('!HideMeter', 'ScrollRail')
        SKIN:Bang('!HideMeter', 'ScrollThumb')
        SKIN:Bang('!HideMeter', 'ScrollThumbGlow')
        SKIN:Bang('!HideMeter', 'ScrollUp')
        SKIN:Bang('!HideMeter', 'ScrollDown')

        return ''
    end

    loadLines()
    clampScroll()
    updateScrollButtons()

    if getMaxOffset() > 0 then
        updateScrollThumb()
    end

    -- Empty Notes state
    if #lines == 0 then

        SKIN:Bang(
            '!ShowMeter',
            'NotesEmpty'
        )

        SKIN:Bang(
            '!HideMeter',
            'Notes'
        )

        SKIN:Bang(
            '!HideMeter',
            'NotesGlow'
        )

        SKIN:Bang(
            '!UpdateMeter',
            'NotesEmpty'
        )

        return ''
    end

    SKIN:Bang(
        '!HideMeter',
        'NotesEmpty'
    )

    SKIN:Bang(
        '!ShowMeter',
        'Notes'
    )

    SKIN:Bang(
        '!ShowMeter',
        'NotesGlow'
    )

    local output = {}
    local firstLine = scrollOffset + 1
    local lastLine = math.min(
        firstLine + visibleLines - 1,
        #lines
    )

    for i = firstLine, lastLine do
        table.insert(output, lines[i])
    end

    return table.concat(output, '\n')
end


-- ==================================================
-- SCROLL UP
-- ==================================================

function ScrollUp()
    loadLines()

    scrollOffset = scrollOffset - 2
    clampScroll()

    refreshNotes()
end


-- ==================================================
-- SCROLL DOWN
-- ==================================================

function ScrollDown()
    loadLines()

    scrollOffset = scrollOffset + 2
    clampScroll()

    refreshNotes()
end


-- ==================================================
-- SCROLL TO BOTTOM
-- ==================================================

function ScrollBottom()
    loadLines()

    scrollOffset = getMaxOffset()

    refreshNotes()
end