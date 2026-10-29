local tasks = {}
local scrollOffset = 0
local visibleTasks = 6

local feedbackTaskId = nil
local feedbackUntil = 0

function Initialize()
    path = SKIN:GetVariable('@') .. 'Tasks.txt'
end


-- ==================================================
-- LOAD TASKS
-- ==================================================

local function loadTasks()

    tasks = {}

    local file = io.open(path, 'r')

    if not file then
        return
    end


    for line in file:lines() do

        if line ~= '' then

            local status,
                taskType,
                id,
                weeklyGoal,
                monthlyGoal,
                text =
                string.match(
                    line,
                    '^(%d)|([^|]+)|(%d+)|(%d+)|(%d+)|(.+)$'
                )

            if status
            and taskType
            and id
            and weeklyGoal
            and monthlyGoal
            and text then

                table.insert(tasks, {
                    status = tonumber(status),
                    type = taskType,
                    id = tonumber(id),
                    weeklyGoal = tonumber(weeklyGoal),
                    monthlyGoal = tonumber(monthlyGoal),
                    text = text
                })

            end

        end

    end

    file:close()
end


-- ==================================================
-- SCROLL LIMITS
-- ==================================================

local function getMaxOffset()
    return math.max(0, #tasks - visibleTasks)
end


local function clampScroll()
    local maxOffset = getMaxOffset()

    if scrollOffset < 0 then
        scrollOffset = 0
    elseif scrollOffset > maxOffset then
        scrollOffset = maxOffset
    end
end

local function tasksViewIsActive()

    return
        SKIN:GetVariable('CurrentView') == 'Tasks'
        and SKIN:GetVariable('WriteMode') ~= '1'
        and SKIN:GetVariable('TaskConfirm') ~= '1'
        and SKIN:GetVariable('TaskDetailMode') ~= '1'

end

-- ==================================================
-- TASK METERS
-- ==================================================

local function updateTaskMeters()

    if not tasksViewIsActive() then

        for slot = 1, visibleTasks do
            SKIN:Bang('!HideMeter', 'Task' .. slot)
        end

        SKIN:Bang('!HideMeter', 'TasksEmpty')

        return
    end


    -- Empty state
    if #tasks == 0 then

        for slot = 1, visibleTasks do
            SKIN:Bang('!HideMeter', 'Task' .. slot)
        end

        SKIN:Bang('!ShowMeter', 'TasksEmpty')

        return

    else
        SKIN:Bang('!HideMeter', 'TasksEmpty')
    end


    -- Populate visible task rows
    for slot = 1, visibleTasks do

        local meterName = 'Task' .. slot
        local index = scrollOffset + slot
        local task = tasks[index]

        if task then

            local prefix = '[ ] '
            local color = '105,245,125,255'


            -- Repeating-task completion feedback
            if feedbackTaskId == task.id and os.time() < feedbackUntil then

                prefix = '[+1] '
                color = '125,255,145,255'

            elseif task.status == 1 then

                prefix = '[X] '
                color = '40,110,55,170'

            end


            SKIN:Bang(
                '!SetOption',
                meterName,
                'Text',
                prefix .. task.text
            )


            SKIN:Bang(
                '!SetOption',
                meterName,
                'FontColor',
                color
            )


            -- Different click behavior depending on task type
            local clickAction = ''

            if task.type == 'repeat' then

                clickAction =
                    '[!SetVariable ToggleTaskId "' ..
                    task.id ..
                    '"]' ..
                    '[!UpdateMeasure MeasureCompleteRepeatTask]' ..
                    '[!CommandMeasure MeasureCompleteRepeatTask "Run"]'

            else

                clickAction =
                    '[!SetVariable ToggleTaskId "' ..
                    task.id ..
                    '"]' ..
                    '[!UpdateMeasure MeasureToggleNormalTask]' ..
                    '[!CommandMeasure MeasureToggleNormalTask "Run"]'

            end


            SKIN:Bang(
                '!SetOption',
                meterName,
                'LeftMouseUpAction',
                clickAction
            )

            local rightClickAction =
                '[!CommandMeasure MeasureTasks "OpenTaskDetails(' ..
                task.id ..
                ')"]'

            SKIN:Bang(
                '!SetOption',
                meterName,
                'RightMouseUpAction',
                rightClickAction
            )


            SKIN:Bang('!ShowMeter', meterName)

        else

            SKIN:Bang('!HideMeter', meterName)

        end
    end
end


-- ==================================================
-- SCROLLBAR
-- ==================================================

local function updateScrollbar()

    local maxOffset =
        getMaxOffset()

    if not tasksViewIsActive()
        or maxOffset <= 0 then

        SKIN:Bang('!HideMeter', 'TaskScrollRail')
        SKIN:Bang('!HideMeter', 'TaskScrollThumb')
        SKIN:Bang('!HideMeter', 'TaskScrollThumbGlow')
        SKIN:Bang('!HideMeter', 'TaskScrollUp')
        SKIN:Bang('!HideMeter', 'TaskScrollDown')

        return
    end


    SKIN:Bang('!ShowMeter', 'TaskScrollRail')
    SKIN:Bang('!ShowMeter', 'TaskScrollThumb')
    SKIN:Bang('!ShowMeter', 'TaskScrollThumbGlow')
    SKIN:Bang('!ShowMeter', 'TaskScrollUp')
    SKIN:Bang('!ShowMeter', 'TaskScrollDown')


    -- Up arrow state
    if scrollOffset <= 0 then

        SKIN:Bang(
            '!SetOption',
            'TaskScrollUp',
            'Shape',
            'Path TaskUpArrow | Fill Color 40,110,55,100 | StrokeWidth 0'
        )

    else

        SKIN:Bang(
            '!SetOption',
            'TaskScrollUp',
            'Shape',
            'Path TaskUpArrow | Fill Color 70,180,90,255 | StrokeWidth 0'
        )

    end


    -- Down arrow state
    if scrollOffset >= maxOffset then

        SKIN:Bang(
            '!SetOption',
            'TaskScrollDown',
            'Shape',
            'Path TaskDownArrow | Fill Color 40,110,55,100 | StrokeWidth 0'
        )

    else

        SKIN:Bang(
            '!SetOption',
            'TaskScrollDown',
            'Shape',
            'Path TaskDownArrow | Fill Color 70,180,90,255 | StrokeWidth 0'
        )

    end


    -- Scroll thumb position
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
        'TaskScrollThumb',
        'Y',
        tostring(y)
    )

    SKIN:Bang(
        '!SetOption',
        'TaskScrollThumbGlow',
        'Y',
        tostring(y - 1)
    )


    SKIN:Bang('!UpdateMeter', 'TaskScrollRail')
    SKIN:Bang('!UpdateMeter', 'TaskScrollThumb')
    SKIN:Bang('!UpdateMeter', 'TaskScrollThumbGlow')
    SKIN:Bang('!UpdateMeter', 'TaskScrollUp')
    SKIN:Bang('!UpdateMeter', 'TaskScrollDown')
end


-- ==================================================
-- PENDING COUNT
-- ==================================================

local function getPendingCount()

    local count = 0

    for _, task in ipairs(tasks) do
        if task.status == 0 then
            count = count + 1
        end
    end

    return count
end


-- ==================================================
-- REFRESH
-- ==================================================

local function refresh()

    SKIN:Bang('!UpdateMeasure', 'MeasureTasks')
    SKIN:Bang('!UpdateMeterGroup', 'TasksView')
    SKIN:Bang('!Redraw')

end


-- ==================================================
-- MAIN UPDATE
-- ==================================================

function CompleteRepeat(taskId)

    feedbackTaskId = tonumber(taskId)
    feedbackUntil = os.time() + 1

    refresh()

end

function Update()

    if feedbackTaskId ~= nil
    and os.time() >= feedbackUntil then

        feedbackTaskId = nil
        feedbackUntil = 0

    end

    loadTasks()
    clampScroll()
    updateTaskMeters()
    updateScrollbar()

    return getPendingCount()
end

-- ==================================================
-- TASK DETAILS
-- ==================================================

function OpenTaskDetails(taskId)

    loadTasks()

    local targetId = tonumber(taskId)

    if not targetId then
        return
    end

    for _, task in ipairs(tasks) do

        if task.id == targetId then

            SKIN:Bang(
                '!SetVariable',
                'SelectedTaskId',
                tostring(task.id)
            )

            SKIN:Bang(
                '!SetVariable',
                'SelectedTaskName',
                task.text
            )

            SKIN:Bang(
                '!SetVariable',
                'SelectedTaskType',
                task.type
            )

            SKIN:Bang(
                '!SetVariable',
                'SelectedTaskWeekly',
                tostring(task.weeklyGoal or 0)
            )

            SKIN:Bang(
                '!SetVariable',
                'SelectedTaskMonthly',
                tostring(task.monthlyGoal or 0)
            )

            SKIN:Bang(
                '!SetVariable',
                'TaskDetailMode',
                '1'
            )

            SKIN:Bang(
                '!CommandMeasure',
                'MeasureViewController',
                'ShowTaskDetails()'
            )

            return
        end
    end
end


-- ==================================================
-- SCROLLING
-- ==================================================

function ScrollUp()

    loadTasks()

    scrollOffset = scrollOffset - 1
    clampScroll()

    refresh()
end


function ScrollDown()

    loadTasks()

    scrollOffset = scrollOffset + 1
    clampScroll()

    refresh()
end


function ScrollBottom()

    loadTasks()

    scrollOffset = getMaxOffset()

    refresh()
end