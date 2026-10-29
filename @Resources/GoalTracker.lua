local goals = {}
local visibleGoals = {}

local currentPeriod = 'week'
local visibleSlots = 3
local scrollOffset = 0


function Initialize()

    tasksPath = SKIN:GetVariable('@') .. 'Tasks.txt'
    historyPath = SKIN:GetVariable('@') .. 'TaskHistory.txt'

end


-- ==================================================
-- DATE HELPERS
-- ==================================================

local function getCurrentWeekStart()

    local now = os.date('*t')
    local daysSinceMonday = (now.wday + 5) % 7

    local todayMidnight = os.time({
        year = now.year,
        month = now.month,
        day = now.day,
        hour = 0,
        min = 0,
        sec = 0
    })

    return todayMidnight - (daysSinceMonday * 86400)
end


local function getCurrentMonthStart()

    local now = os.date('*t')

    return os.time({
        year = now.year,
        month = now.month,
        day = 1,
        hour = 0,
        min = 0,
        sec = 0
    })
end


local function parseTimestamp(timestamp)

    local year, month, day,
          hour, minute, second =
        string.match(
            timestamp,
            '^(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d)$'
        )

    if not year then
        return nil
    end

    return os.time({
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = tonumber(hour),
        min = tonumber(minute),
        sec = tonumber(second)
    })
end

local function getMaxOffset()

    return math.max(
        0,
        #visibleGoals - visibleSlots
    )

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
-- LOAD GOALS
-- ==================================================

local function loadGoals()

    goals = {}

    local file = io.open(tasksPath, 'r')

    if not file then
        return
    end

    for line in file:lines() do

        local _,
            taskType,
            id,
            weeklyGoal,
            monthlyGoal,
            text =
            string.match(
                line,
                '^(%d)|([^|]+)|(%d+)|(%d+)|(%d+)|(.+)$'
            )

        if taskType == 'repeat' then

            weeklyGoal = tonumber(weeklyGoal) or 0
            monthlyGoal = tonumber(monthlyGoal) or 0

            if weeklyGoal > 0 or monthlyGoal > 0 then

                table.insert(goals, {
                    id = tonumber(id),
                    text = text,

                    weeklyGoal = weeklyGoal,
                    monthlyGoal = monthlyGoal,

                    weeklyCount = 0,
                    monthlyCount = 0
                })

            end
        end
    end

    file:close()

    table.sort(goals, function(a, b)
        return a.id < b.id
    end)
end


-- ==================================================
-- COMPLETION HISTORY
-- ==================================================

local function loadHistory()

    local file = io.open(historyPath, 'r')

    if not file then
        return
    end

    local weekStart = getCurrentWeekStart()
    local monthStart = getCurrentMonthStart()
    local now = os.time()

    local byId = {}

    for _, goal in ipairs(goals) do
        byId[goal.id] = goal
    end


    for line in file:lines() do

        local id, timestamp =
            string.match(line, '^(%d+)|(.+)$')

        id = tonumber(id)

        local goal = byId[id]

        if goal then

            local completionTime =
                parseTimestamp(timestamp)

            if completionTime then

                if completionTime >= monthStart
                    and completionTime <= now then

                    goal.monthlyCount =
                        goal.monthlyCount + 1
                end

                if completionTime >= weekStart
                    and completionTime <= now then

                    goal.weeklyCount =
                        goal.weeklyCount + 1
                end
            end
        end
    end

    file:close()
end


-- ==================================================
-- PERIOD LABEL
-- ==================================================

local function updatePeriodLabel()

    if currentPeriod == 'week' then

        local weekStart = getCurrentWeekStart()
        local weekEnd = weekStart + (6 * 86400)

        local label =
            'WEEKLY // ' ..
            string.upper(os.date('%b %d', weekStart)) ..
            ' - ' ..
            string.upper(os.date('%b %d', weekEnd))

        SKIN:Bang(
            '!SetOption',
            'GoalPeriodLabel',
            'Text',
            label
        )

    else

        local label =
            'MONTHLY // ' ..
            string.upper(os.date('%B'))

        SKIN:Bang(
            '!SetOption',
            'GoalPeriodLabel',
            'Text',
            label
        )

    end
end


-- ==================================================
-- BUILD CURRENT GOAL LIST
-- ==================================================

local function buildVisibleGoals()

    visibleGoals = {}

    for _, goal in ipairs(goals) do

        if currentPeriod == 'week'
            and goal.weeklyGoal > 0 then

            table.insert(visibleGoals, goal)

        elseif currentPeriod == 'month'
            and goal.monthlyGoal > 0 then

            table.insert(visibleGoals, goal)

        end
    end
end

local function goalsViewIsActive()

    return
        SKIN:GetVariable('CurrentView') == 'Goals'
        and SKIN:GetVariable('WriteMode') ~= '1'
        and SKIN:GetVariable('TaskConfirm') ~= '1'

end

local function updateScrollButtons()

    local maxOffset =
        getMaxOffset()

        if not goalsViewIsActive()
        or maxOffset <= 0 then

        SKIN:Bang('!HideMeter', 'GoalScrollUp')
        SKIN:Bang('!HideMeter', 'GoalScrollDown')

        return
    end


    SKIN:Bang('!ShowMeter', 'GoalScrollUp')
    SKIN:Bang('!ShowMeter', 'GoalScrollDown')


    if scrollOffset <= 0 then

        SKIN:Bang(
            '!SetOption',
            'GoalScrollUp',
            'Shape',
            'Path GoalUpArrow | Fill Color 40,110,55,100 | StrokeWidth 0'
        )

    else

        SKIN:Bang(
            '!SetOption',
            'GoalScrollUp',
            'Shape',
            'Path GoalUpArrow | Fill Color 70,180,90,255 | StrokeWidth 0'
        )

    end


    if scrollOffset >= maxOffset then

        SKIN:Bang(
            '!SetOption',
            'GoalScrollDown',
            'Shape',
            'Path GoalDownArrow | Fill Color 40,110,55,100 | StrokeWidth 0'
        )

    else

        SKIN:Bang(
            '!SetOption',
            'GoalScrollDown',
            'Shape',
            'Path GoalDownArrow | Fill Color 70,180,90,255 | StrokeWidth 0'
        )

    end

end

-- ==================================================
-- DRAW GOAL METERS
-- ==================================================

local function updateGoalMeters()

    if not goalsViewIsActive() then

        for slot = 1, visibleSlots do
            SKIN:Bang('!HideMeter', 'GoalName' .. slot)
            SKIN:Bang('!HideMeter', 'GoalRail' .. slot)
            SKIN:Bang('!HideMeter', 'GoalFillGlow' .. slot)
            SKIN:Bang('!HideMeter', 'GoalFill' .. slot)
            SKIN:Bang('!HideMeter', 'GoalCount' .. slot)
        end

        SKIN:Bang('!HideMeter', 'GoalsEmpty')
        return
    end


    if #visibleGoals == 0 then

        for slot = 1, visibleSlots do
            SKIN:Bang('!HideMeter', 'GoalName' .. slot)
            SKIN:Bang('!HideMeter', 'GoalRail' .. slot)
            SKIN:Bang('!HideMeter', 'GoalFillGlow' .. slot)
            SKIN:Bang('!HideMeter', 'GoalFill' .. slot)
            SKIN:Bang('!HideMeter', 'GoalCount' .. slot)
        end

        if currentPeriod == 'week' then
            SKIN:Bang(
                '!SetOption',
                'GoalsEmpty',
                'Text',
                '> NO WEEKLY GOALS'
            )
        else
            SKIN:Bang(
                '!SetOption',
                'GoalsEmpty',
                'Text',
                '> NO MONTHLY GOALS'
            )
        end

        SKIN:Bang('!ShowMeter', 'GoalsEmpty')
        return

    else

        SKIN:Bang('!HideMeter', 'GoalsEmpty')

    end


    for slot = 1, visibleSlots do

        local index = scrollOffset + slot
        local goal = visibleGoals[index]

        if goal then

            local count
            local target

            if currentPeriod == 'week' then
                count = goal.weeklyCount
                target = goal.weeklyGoal
            else
                count = goal.monthlyCount
                target = goal.monthlyGoal
            end


            local progress = 0

            if target > 0 then
                progress = count / target
            end

            progress =
                math.max(
                    0,
                    math.min(
                        progress,
                        1
                    )
                )


            -- Maximum bar width
            local maxWidth = 190

            local fillWidth =
                math.floor(maxWidth * progress)

            local completed = 
                count >= target    
            
            SKIN:Bang(
                '!SetOption',
                'GoalName' .. slot,
                'Text',
                string.upper(goal.text)
            )


            SKIN:Bang(
                '!SetOption',
                'GoalCount' .. slot,
                'Text',
                count .. ' / ' .. target
            )


            SKIN:Bang(
                '!SetOption',
                'GoalFill' .. slot,
                'Shape',
                'Rectangle 0,0,' ..
                fillWidth ..
                ',4 | Fill Color #AccentColor# | StrokeWidth 0'
            )

            SKIN:Bang(
                '!SetOption',
                'GoalFillGlow' .. slot,
                'Shape',
                'Rectangle 0,0,' ..
                fillWidth ..
                ',6 | Fill Color #GlowStrong# | StrokeWidth 0'
            )

            if completed then
                SKIN:Bang(
                '!SetOption',
                'GoalName' .. slot,
                'FontColor',
                '#AccentColor#'
                )

                SKIN:Bang(
                '!SetOption',
                'GoalCount' .. slot,
                'FontColor',
                '#AccentColor#'
                )

            else
                SKIN:Bang(
                '!SetOption',
                'GoalName' .. slot,
                'FontColor',
                '#TextColor#'
                )

                SKIN:Bang(
                '!SetOption',
                'GoalCount' .. slot,
                'FontColor',
                '#MutedColor#'
                )

            end


            SKIN:Bang('!ShowMeter', 'GoalName' .. slot)
            SKIN:Bang('!ShowMeter', 'GoalRail' .. slot)
            SKIN:Bang('!ShowMeter', 'GoalFillGlow' .. slot)
            SKIN:Bang('!ShowMeter', 'GoalFill' .. slot)
            SKIN:Bang('!ShowMeter', 'GoalCount' .. slot)

        else

            SKIN:Bang('!HideMeter', 'GoalName' .. slot)
            SKIN:Bang('!HideMeter', 'GoalRail' .. slot)
            SKIN:Bang('!HideMeter', 'GoalFillGlow' .. slot)
            SKIN:Bang('!HideMeter', 'GoalFill' .. slot)
            SKIN:Bang('!HideMeter', 'GoalCount' .. slot)

        end
    end
    updateScrollButtons()
end


-- ==================================================
-- PERIOD SWITCHING
-- ==================================================

function ShowWeek()

    currentPeriod = 'week'
    scrollOffset = 0

    SKIN:Bang(
        '!SetOption',
        'GoalWeek',
        'FontColor',
        '#AccentColor#'
    )

    SKIN:Bang(
        '!SetOption',
        'GoalMonth',
        'FontColor',
        '#DimColor#'
    )

    SKIN:Bang(
        '!SetOption',
        'GoalPeriodIndicator',
        'X',
        '210'
    )

    loadGoals()
    loadHistory()
    buildVisibleGoals()
    updatePeriodLabel()
    updateGoalMeters()

    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end


function ShowMonth()

    currentPeriod = 'month'
    scrollOffset = 0

    SKIN:Bang(
        '!SetOption',
        'GoalWeek',
        'FontColor',
        '#DimColor#'
    )

    SKIN:Bang(
        '!SetOption',
        'GoalMonth',
        'FontColor',
        '#AccentColor#'
    )

    SKIN:Bang(
    '!SetOption',
    'GoalPeriodIndicator',
    'X',
    '248'
    )

    loadGoals()
    loadHistory()
    buildVisibleGoals()
    updatePeriodLabel()
    updateGoalMeters()

    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end

function GoalScrollUp()

    scrollOffset = scrollOffset - 1
    clampScroll()

    updateGoalMeters()

    SKIN:Bang('!UpdateMeterGroup', 'GoalsView')
    SKIN:Bang('!Redraw')

end


function GoalScrollDown()

    scrollOffset = scrollOffset + 1
    clampScroll()

    updateGoalMeters()

    SKIN:Bang('!UpdateMeterGroup', 'GoalsView')
    SKIN:Bang('!Redraw')

end

-- ==================================================
-- UPDATE
-- ==================================================

function Update()

    loadGoals()
    loadHistory()
    buildVisibleGoals()
    updatePeriodLabel()
    updateGoalMeters()

    return #visibleGoals
end