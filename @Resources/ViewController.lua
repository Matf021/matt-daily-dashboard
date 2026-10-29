function Initialize()
end

local function hideAllScrollControls()

    local meters = {
        'ScrollRail',
        'ScrollThumbGlow',
        'ScrollThumb',
        'ScrollUp',
        'ScrollDown',

        'TaskScrollRail',
        'TaskScrollThumbGlow',
        'TaskScrollThumb',
        'TaskScrollUp',
        'TaskScrollDown',

        'GoalScrollUp',
        'GoalScrollDown'
    }

    for _, meter in ipairs(meters) do
        SKIN:Bang(
            '!HideMeter',
            meter
        )
    end

end

local function restoreTaskViewChrome(
    statusText,
    statusColor
)

    SKIN:Bang(
        '!SetOption',
        'ViewNotes',
        'FontColor',
        '#DimColor#'
    )

    SKIN:Bang(
        '!SetOption',
        'ViewTasks',
        'FontColor',
        '#AccentColor#'
    )

    SKIN:Bang(
        '!SetOption',
        'ViewGoals',
        'FontColor',
        '#DimColor#'
    )

    SKIN:Bang(
        '!SetOption',
        'ViewIndicator',
        'X',
        '62'
    )

    SKIN:Bang(
        '!SetOption',
        'HeaderLabel',
        'Text',
        'DATA // PENDING TASKS'
    )

    SKIN:Bang(
        '!SetOption',
        'HeaderGlow',
        'Text',
        'DATA // PENDING TASKS'
    )

    SKIN:Bang(
        '!SetOption',
        'SystemStatus',
        'Text',
        statusText
    )

    SKIN:Bang(
        '!SetOption',
        'SystemStatus',
        'FontColor',
        statusColor
    )

    SKIN:Bang(
        '!SetOption',
        'FooterLeft',
        'Text',
        'QUEUE: ACTIVE'
    )

end

local function buildTaskSummary(
    taskType,
    weekly,
    monthly
)

    if taskType == 'normal' then
        return 'TYPE     // NORMAL'
    end

    local details =
        'TYPE     // REPEAT'

    if weekly > 0 then

        details =
            details ..
            '\nWEEKLY   // ' ..
            tostring(weekly)

    end

    if monthly > 0 then

        details =
            details ..
            '\nMONTHLY  // ' ..
            tostring(monthly)

    end

    if weekly == 0
    and monthly == 0 then

        details =
            details ..
            '\nTRACKING // NONE'

    end

    return details

end

local function positiveInteger(value)

    local number =
        tonumber(value)

    if not number
    or number < 1 then
        return nil
    end

    return math.floor(number)

end

function CancelInput()

    local currentView =
        SKIN:GetVariable('CurrentView')


    -- ==============================================
    -- EXIT INPUT MODE
    -- ==============================================

    SKIN:Bang('!SetVariable', 'TaskConfirm', '0')
    SKIN:Bang('!SetVariable', 'TaskDetailMode', '0')
    SKIN:Bang('!SetVariable', 'WriteMode', '0')

    SKIN:Bang('!HideMeterGroup', 'WriteView')
    SKIN:Bang('!HideMeterGroup', 'TaskSavedView')
    SKIN:Bang('!HideMeter', 'GoalInputHint')

    SKIN:Bang('!ShowMeterGroup', 'SharedViewport')
    SKIN:Bang('!ShowMeterGroup', 'ViewSelector')


    hideAllScrollControls()

    -- ==============================================
    -- RESTORE SOURCE VIEW
    -- ==============================================

    if currentView == 'Tasks' then

        SKIN:Bang('!HideMeterGroup', 'NotesView')
        SKIN:Bang('!HideMeterGroup', 'GoalsView')
        SKIN:Bang('!ShowMeterGroup', 'TasksView')

        SKIN:Bang(
            '!SetOption',
            'HeaderLabel',
            'Text',
            'DATA // PENDING TASKS'
        )

        SKIN:Bang(
            '!SetOption',
            'HeaderGlow',
            'Text',
            'DATA // PENDING TASKS'
        )

        SKIN:Bang(
            '!SetOption',
            'FooterLeft',
            'Text',
            'QUEUE: ACTIVE'
        )

        SKIN:Bang('!UpdateMeasure', 'MeasureTasks')

        -- Restore static task action buttons after cancelling input.
        SKIN:Bang('!ShowMeter', 'AddTask')
        SKIN:Bang('!ShowMeter', 'ClearDone')

    else

        SKIN:Bang('!HideMeterGroup', 'TasksView')
        SKIN:Bang('!HideMeterGroup', 'GoalsView')
        SKIN:Bang('!ShowMeterGroup', 'NotesView')

        SKIN:Bang(
            '!SetOption',
            'HeaderLabel',
            'Text',
            'DATA // QUICK NOTES'
        )

        SKIN:Bang(
            '!SetOption',
            'HeaderGlow',
            'Text',
            'DATA // QUICK NOTES'
        )

        SKIN:Bang(
            '!SetOption',
            'FooterLeft',
            'Text',
            'LOG: ACTIVE'
        )

        SKIN:Bang('!UpdateMeasure', 'MeasureNotes')

        -- Restore static Notes action buttons after cancelling input.
        -- These are hidden when entering write mode and ReadNotes.lua
        -- does not control them.
        SKIN:Bang('!ShowMeter', 'AddNote')
        SKIN:Bang('!ShowMeter', 'ArchiveNow')

    end


    -- ==============================================
    -- RESTORE SYSTEM STATUS
    -- ==============================================

    SKIN:Bang(
        '!SetOption',
        'SystemStatus',
        'Text',
        'SYS // READY'
    )

    SKIN:Bang(
        '!SetOption',
        'SystemStatus',
        'FontColor',
        '#DimColor#'
    )

    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')

end


function Update()
    return ''
end

-- ==================================================
-- TASK DETAILS
-- ==================================================

function ShowTaskDetails()

    local taskId =
        SKIN:GetVariable('SelectedTaskId')

    local taskName =
        SKIN:GetVariable('SelectedTaskName')

    local taskType =
        SKIN:GetVariable('SelectedTaskType')

    local weekly =
        tonumber(SKIN:GetVariable('SelectedTaskWeekly')) or 0

    local monthly =
        tonumber(SKIN:GetVariable('SelectedTaskMonthly')) or 0


    -- Block the normal Tasks renderer while this screen is open.
    SKIN:Bang('!SetVariable', 'TaskDetailMode', '1')

    SKIN:Bang('!HideMeterGroup', 'TasksView')
    SKIN:Bang('!HideMeterGroup', 'NotesView')
    SKIN:Bang('!HideMeterGroup', 'GoalsView')
    SKIN:Bang('!HideMeterGroup', 'ViewSelector')
    SKIN:Bang('!HideMeterGroup', 'WriteView')
    SKIN:Bang('!HideMeterGroup', 'TaskSavedView')

    hideAllScrollControls()

    -- Keep the viewport frame as the details panel.
    SKIN:Bang('!ShowMeterGroup', 'SharedViewport')


    local typeText =
        'TYPE     // ' .. string.upper(taskType)

    local weeklyText = ''
    local monthlyText = ''

    if taskType == 'repeat' then

        if weekly > 0 then
            weeklyText =
                'WEEKLY   // ' .. tostring(weekly)
        else
            weeklyText =
                'WEEKLY   // --'
        end

        if monthly > 0 then
            monthlyText =
                'MONTHLY  // ' .. tostring(monthly)
        else
            monthlyText =
                'MONTHLY  // --'
        end

    else

        weeklyText =
            'WEEKLY   // N/A'

        monthlyText =
            'MONTHLY  // N/A'
    end


    SKIN:Bang(
        '!SetOption',
        'TaskDetailsName',
        'Text',
        taskName
    )

    SKIN:Bang(
        '!SetOption',
        'TaskDetailsType',
        'Text',
        typeText
    )

    SKIN:Bang(
        '!SetOption',
        'TaskDetailsWeekly',
        'Text',
        weeklyText
    )

    SKIN:Bang(
        '!SetOption',
        'TaskDetailsMonthly',
        'Text',
        monthlyText
    )

    SKIN:Bang(
        '!SetOption',
        'HeaderLabel',
        'Text',
        'DATA // TASK DETAILS'
    )

    SKIN:Bang(
        '!SetOption',
        'HeaderGlow',
        'Text',
        'DATA // TASK DETAILS'
    )

    SKIN:Bang(
        '!SetOption',
        'SystemStatus',
        'Text',
        'SYS // INSPECT'
    )

    SKIN:Bang(
        '!SetOption',
        'SystemStatus',
        'FontColor',
        '#MutedColor#'
    )

    SKIN:Bang(
        '!SetOption',
        'FooterLeft',
        'Text',
        'TASK ID // ' .. taskId
    )

    SKIN:Bang('!ShowMeterGroup', 'TaskDetailsView')

    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end


function HideTaskEditChoices()

    SKIN:Bang('!HideMeter', 'TaskEditTypeNormal')
    SKIN:Bang('!HideMeter', 'TaskEditTypeRepeat')

    SKIN:Bang('!HideMeter', 'TaskEditTrackNone')
    SKIN:Bang('!HideMeter', 'TaskEditTrackWeekly')
    SKIN:Bang('!HideMeter', 'TaskEditTrackMonthly')
    SKIN:Bang('!HideMeter', 'TaskEditTrackBoth')

    SKIN:Bang('!HideMeter', 'TaskEditUnitHint')
end


function StartEditTask()

    local currentName =
        SKIN:GetVariable('SelectedTaskName')

    SKIN:Bang('!SetVariable', 'TaskDetailMode', '1')
    SKIN:Bang('!SetVariable', 'EditTaskName', currentName)
    SKIN:Bang(
        '!SetVariable',
        'EditTaskType',
        SKIN:GetVariable('SelectedTaskType')
    )
    SKIN:Bang(
        '!SetVariable',
        'EditTaskWeekly',
        SKIN:GetVariable('SelectedTaskWeekly')
    )
    SKIN:Bang(
        '!SetVariable',
        'EditTaskMonthly',
        SKIN:GetVariable('SelectedTaskMonthly')
    )
    SKIN:Bang('!SetVariable', 'EditTaskStep', '1')

    SKIN:Bang('!HideMeterGroup', 'TaskDetailsView')
    SKIN:Bang('!HideMeterGroup', 'TaskDeleteView')
    SKIN:Bang('!HideMeterGroup', 'TaskEditedView')

    HideTaskEditChoices()

    SKIN:Bang(
        '!SetOption',
        'TaskEditPrompt',
        'Text',
        '> TASK NAME'
    )

    SKIN:Bang(
        '!SetOption',
        'TaskEditCurrent',
        'Text',
        'CURRENT // ' .. currentName
    )

    SKIN:Bang(
        '!SetOption',
        'MeasureEditTaskNameInput',
        'DefaultValue',
        currentName
    )

    SKIN:Bang(
        '!SetOption',
        'HeaderLabel',
        'Text',
        'DATA // EDIT TASK'
    )

    SKIN:Bang(
        '!SetOption',
        'HeaderGlow',
        'Text',
        'DATA // EDIT TASK'
    )

    SKIN:Bang(
        '!SetOption',
        'SystemStatus',
        'Text',
        'SYS // EDIT'
    )

    SKIN:Bang(
        '!SetOption',
        'SystemStatus',
        'FontColor',
        '#MutedColor#'
    )

    -- IMPORTANT: do not ShowMeterGroup TaskEditView here.
    -- That group also contains TYPE / TRACKING choices and would
    -- reveal every wizard option at once.
    SKIN:Bang('!ShowMeter', 'TaskEditTitle')
    SKIN:Bang('!ShowMeter', 'TaskEditPrompt')
    SKIN:Bang('!ShowMeter', 'TaskEditCurrent')
    SKIN:Bang('!ShowMeter', 'TaskEditCancel')

    SKIN:Bang('!UpdateMeasure', 'MeasureEditTaskNameInput')
    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')

    SKIN:Bang(
        '!CommandMeasure',
        'MeasureEditTaskNameInput',
        'ExecuteBatch ALL'
    )
end


function AfterEditName()

    local name =
        SKIN:GetVariable('EditTaskName')

    if not name or name == '' then

        SKIN:Bang(
            '!SetOption',
            'TaskEditPrompt',
            'Text',
            '> NAME CANNOT BE EMPTY'
        )

        SKIN:Bang('!UpdateMeter', 'TaskEditPrompt')
        SKIN:Bang('!Redraw')
        return
    end

    HideTaskEditChoices()

    SKIN:Bang('!SetVariable', 'EditTaskStep', '2')

    SKIN:Bang(
        '!SetOption',
        'TaskEditPrompt',
        'Text',
        '> TASK TYPE'
    )

    SKIN:Bang(
        '!SetOption',
        'TaskEditCurrent',
        'Text',
        'NAME // ' .. name
    )

    SKIN:Bang('!ShowMeter', 'TaskEditTypeNormal')
    SKIN:Bang('!ShowMeter', 'TaskEditTypeRepeat')

    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end


function SelectEditNormal()

    SKIN:Bang('!SetVariable', 'EditTaskType', 'normal')
    SKIN:Bang('!SetVariable', 'EditTaskWeekly', '0')
    SKIN:Bang('!SetVariable', 'EditTaskMonthly', '0')

    SaveEditedTask()
end


function SelectEditRepeat()

    SKIN:Bang('!SetVariable', 'EditTaskType', 'repeat')
    SKIN:Bang('!SetVariable', 'EditTaskStep', '3')

    HideTaskEditChoices()

    SKIN:Bang(
        '!SetOption',
        'TaskEditPrompt',
        'Text',
        '> REPEAT TRACKING'
    )

    SKIN:Bang(
        '!SetOption',
        'TaskEditCurrent',
        'Text',
        'SELECT // GOAL TRACKING'
    )

    SKIN:Bang('!ShowMeter', 'TaskEditTrackNone')
    SKIN:Bang('!ShowMeter', 'TaskEditTrackWeekly')
    SKIN:Bang('!ShowMeter', 'TaskEditTrackMonthly')
    SKIN:Bang('!ShowMeter', 'TaskEditTrackBoth')

    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end


function SelectEditTracking(mode)

    HideTaskEditChoices()

    if mode == 'none' then

        SKIN:Bang('!SetVariable', 'EditTaskWeekly', '0')
        SKIN:Bang('!SetVariable', 'EditTaskMonthly', '0')

        SaveEditedTask()
        return
    end

    if mode == 'weekly' then

        SKIN:Bang('!SetVariable', 'EditTaskStep', '4')
        SKIN:Bang('!SetVariable', 'EditTaskMonthly', '0')

        SKIN:Bang(
            '!SetOption',
            'TaskEditPrompt',
            'Text',
            '> WEEKLY TARGET'
        )

        SKIN:Bang('!ShowMeter', 'TaskEditUnitHint')
        SKIN:Bang('!UpdateMeter', '*')
        SKIN:Bang('!Redraw')

        SKIN:Bang(
            '!CommandMeasure',
            'MeasureEditGoalInput',
            'ExecuteBatch ALL'
        )
        return
    end

    if mode == 'monthly' then

        SKIN:Bang('!SetVariable', 'EditTaskStep', '5')
        SKIN:Bang('!SetVariable', 'EditTaskWeekly', '0')

        SKIN:Bang(
            '!SetOption',
            'TaskEditPrompt',
            'Text',
            '> MONTHLY TARGET'
        )

        SKIN:Bang('!ShowMeter', 'TaskEditUnitHint')
        SKIN:Bang('!UpdateMeter', '*')
        SKIN:Bang('!Redraw')

        SKIN:Bang(
            '!CommandMeasure',
            'MeasureEditGoalInput',
            'ExecuteBatch ALL'
        )
        return
    end

    if mode == 'both' then

        SKIN:Bang('!SetVariable', 'EditTaskStep', '6')

        SKIN:Bang(
            '!SetOption',
            'TaskEditPrompt',
            'Text',
            '> WEEKLY TARGET'
        )

        SKIN:Bang('!ShowMeter', 'TaskEditUnitHint')
        SKIN:Bang('!UpdateMeter', '*')
        SKIN:Bang('!Redraw')

        SKIN:Bang(
            '!CommandMeasure',
            'MeasureEditGoalInput',
            'ExecuteBatch ALL'
        )
        return
    end
end


function ProcessEditGoalInput()

    local step =
        tonumber(SKIN:GetVariable('EditTaskStep')) or 0

    local number =
        positiveInteger(SKIN:GetVariable('EditGoalInputRaw'))

    if not number then

        SKIN:Bang(
            '!SetOption',
            'TaskEditPrompt',
            'Text',
            '> ENTER A NUMBER ABOVE 0'
        )

        SKIN:Bang(
            '!UpdateMeter',
            'TaskEditPrompt'
        )

        SKIN:Bang('!Redraw')

        return

    end

    if step == 4 then

        SKIN:Bang(
            '!SetVariable',
            'EditTaskWeekly',
            tostring(number)
        )

        SKIN:Bang('!SetVariable', 'EditTaskMonthly', '0')

        SaveEditedTask()
        return
    end

    if step == 5 then

        SKIN:Bang('!SetVariable', 'EditTaskWeekly', '0')

        SKIN:Bang(
            '!SetVariable',
            'EditTaskMonthly',
            tostring(number)
        )

        SaveEditedTask()
        return
    end

    if step == 6 then

        SKIN:Bang(
            '!SetVariable',
            'EditTaskWeekly',
            tostring(number)
        )

        SKIN:Bang('!SetVariable', 'EditTaskStep', '7')

        SKIN:Bang(
            '!SetOption',
            'TaskEditPrompt',
            'Text',
            '> MONTHLY TARGET'
        )

        SKIN:Bang('!UpdateMeter', '*')
        SKIN:Bang('!Redraw')

        SKIN:Bang(
            '!CommandMeasure',
            'MeasureEditMonthlyGoalInput',
            'ExecuteBatch ALL'
        )
        return
    end
end


function ProcessEditMonthlyGoalInput()

    local number =
        positiveInteger(SKIN:GetVariable('EditGoalInputRaw'))

    if not number then

        SKIN:Bang(
            '!SetOption',
            'TaskEditPrompt',
            'Text',
            '> ENTER A NUMBER ABOVE 0'
        )

        SKIN:Bang(
            '!UpdateMeter',
            'TaskEditPrompt'
        )

        SKIN:Bang('!Redraw')

        return

    end

    SKIN:Bang(
        '!SetVariable',
        'EditTaskMonthly',
        tostring(number)
    )

    SaveEditedTask()
end


function SaveEditedTask()

    local taskId =
        SKIN:GetVariable('SelectedTaskId')

    local name =
        SKIN:GetVariable('EditTaskName')

    local taskType =
        SKIN:GetVariable('EditTaskType')

    local weekly =
        SKIN:GetVariable('EditTaskWeekly')

    local monthly =
        SKIN:GetVariable('EditTaskMonthly')

    SKIN:Bang(
        '!SetOption',
        'SystemStatus',
        'Text',
        'SYS // SAVING'
    )

    SKIN:Bang(
        '!SetOption',
        'SystemStatus',
        'FontColor',
        '#AccentColor#'
    )

    SKIN:Bang(
        '!SetOption',
        'MeasureSaveEditedTask',
        'Parameter',
        '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "#CURRENTPATH#..\\Scripts\\EditTask.ps1" -TasksFile "#@#Tasks.txt" -TaskId "' ..
        taskId ..
        '" -Task "' ..
        name ..
        '" -Type "' ..
        taskType ..
        '" -WeeklyGoal "' ..
        weekly ..
        '" -MonthlyGoal "' ..
        monthly ..
        '"'
    )

    SKIN:Bang('!UpdateMeasure', 'MeasureSaveEditedTask')
    SKIN:Bang('!CommandMeasure', 'MeasureSaveEditedTask', 'Run')
end


function ShowTaskEdited()

    local name =
        SKIN:GetVariable('EditTaskName')

    local taskType =
        SKIN:GetVariable('EditTaskType')

    local weekly =
        tonumber(SKIN:GetVariable('EditTaskWeekly')) or 0

    local monthly =
        tonumber(SKIN:GetVariable('EditTaskMonthly')) or 0

    local details =
        buildTaskSummary(
            taskType,
            weekly,
            monthly
        )

    SKIN:Bang('!HideMeterGroup', 'TaskEditView')
    HideTaskEditChoices()
    SKIN:Bang('!HideMeter', 'TaskEditTitle')
    SKIN:Bang('!HideMeter', 'TaskEditPrompt')
    SKIN:Bang('!HideMeter', 'TaskEditCurrent')
    SKIN:Bang('!HideMeter', 'TaskEditCancel')

    SKIN:Bang(
        '!SetOption',
        'TaskEditedName',
        'Text',
        name
    )

    SKIN:Bang(
        '!SetOption',
        'TaskEditedGoals',
        'Text',
        details
    )

    SKIN:Bang(
        '!SetOption',
        'HeaderLabel',
        'Text',
        'DATA // EDIT TASK'
    )

    SKIN:Bang(
        '!SetOption',
        'HeaderGlow',
        'Text',
        'DATA // EDIT TASK'
    )

    SKIN:Bang(
        '!SetOption',
        'SystemStatus',
        'Text',
        'SYS // UPDATED'
    )

    SKIN:Bang(
        '!SetOption',
        'SystemStatus',
        'FontColor',
        '#AccentColor#'
    )

    SKIN:Bang('!ShowMeterGroup', 'TaskEditedView')

    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end


function FinishEditTask()

    SKIN:Bang('!HideMeterGroup', 'TaskEditedView')
    SKIN:Bang('!HideMeterGroup', 'TaskEditView')

    SKIN:Bang('!SetVariable', 'TaskDetailMode', '0')
    SKIN:Bang('!SetVariable', 'CurrentView', 'Tasks')

    SKIN:Bang('!SetVariable', 'EditTaskName', '')
    SKIN:Bang('!SetVariable', 'EditTaskType', 'normal')
    SKIN:Bang('!SetVariable', 'EditTaskWeekly', '0')
    SKIN:Bang('!SetVariable', 'EditTaskMonthly', '0')
    SKIN:Bang('!SetVariable', 'EditTaskStep', '0')
    SKIN:Bang('!SetVariable', 'EditGoalInputRaw', '')

    SKIN:Bang('!ShowMeterGroup', 'SharedViewport')
    SKIN:Bang('!ShowMeterGroup', 'ViewSelector')

    restoreTaskViewChrome(
        'SYS // READY',
        '#DimColor#'
    )

    SKIN:Bang('!UpdateMeasure', 'MeasureTasks')
    SKIN:Bang('!UpdateMeasure', 'MeasureGoalTracker')

    -- Restore static task action buttons.
    SKIN:Bang('!ShowMeter', 'AddTask')
    SKIN:Bang('!ShowMeter', 'ClearDone')

    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end


function CancelEditTask()

    SKIN:Bang('!HideMeterGroup', 'TaskEditView')
    SKIN:Bang('!HideMeterGroup', 'TaskEditedView')
    HideTaskEditChoices()
    SKIN:Bang('!HideMeter', 'TaskEditTitle')
    SKIN:Bang('!HideMeter', 'TaskEditPrompt')
    SKIN:Bang('!HideMeter', 'TaskEditCurrent')
    SKIN:Bang('!HideMeter', 'TaskEditCancel')

    -- Keep TaskDetailMode enabled because we are returning to details,
    -- not to the normal Tasks list.
    SKIN:Bang('!SetVariable', 'TaskDetailMode', '1')

    ShowTaskDetails()
end


function ShowDeleteConfirm()

    local taskName =
        SKIN:GetVariable('SelectedTaskName')

    -- TaskDetailMode remains enabled so ReadTasks cannot repaint
    -- the task list underneath the confirmation screen.
    SKIN:Bang('!SetVariable', 'TaskDetailMode', '1')

    SKIN:Bang('!HideMeterGroup', 'TaskDetailsView')

    SKIN:Bang(
        '!SetOption',
        'TaskDeleteName',
        'Text',
        taskName
    )

    SKIN:Bang(
        '!SetOption',
        'HeaderLabel',
        'Text',
        'DATA // TASK DETAILS'
    )

    SKIN:Bang(
        '!SetOption',
        'HeaderGlow',
        'Text',
        'DATA // TASK DETAILS'
    )

    SKIN:Bang(
        '!SetOption',
        'SystemStatus',
        'Text',
        'SYS // CONFIRM DELETE'
    )

    SKIN:Bang(
        '!SetOption',
        'SystemStatus',
        'FontColor',
        '#MutedColor#'
    )

    SKIN:Bang('!ShowMeterGroup', 'TaskDeleteView')

    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end


function CancelDeleteConfirm()

    SKIN:Bang('!HideMeterGroup', 'TaskDeleteView')

    SKIN:Bang(
        '!SetOption',
        'SystemStatus',
        'Text',
        'SYS // INSPECT'
    )

    SKIN:Bang(
        '!SetOption',
        'SystemStatus',
        'FontColor',
        '#MutedColor#'
    )

    SKIN:Bang('!ShowMeterGroup', 'TaskDetailsView')

    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end


function FinishDeleteTask()

    -- Keep all task rendering blocked until the delete is finished
    -- and the normal Tasks view has been restored.
    SKIN:Bang('!HideMeterGroup', 'TaskDeleteView')
    SKIN:Bang('!HideMeterGroup', 'TaskDetailsView')

    SKIN:Bang('!SetVariable', 'TaskDetailMode', '0')
    SKIN:Bang('!SetVariable', 'CurrentView', 'Tasks')

    SKIN:Bang('!SetVariable', 'SelectedTaskId', '0')
    SKIN:Bang('!SetVariable', 'SelectedTaskName', '')
    SKIN:Bang('!SetVariable', 'SelectedTaskType', '')
    SKIN:Bang('!SetVariable', 'SelectedTaskWeekly', '0')
    SKIN:Bang('!SetVariable', 'SelectedTaskMonthly', '0')

    SKIN:Bang('!ShowMeterGroup', 'SharedViewport')
    SKIN:Bang('!ShowMeterGroup', 'ViewSelector')

    restoreTaskViewChrome(
        'SYS // DELETED',
        '#AccentColor#'
    )

    SKIN:Bang('!UpdateMeasure', 'MeasureTasks')
    SKIN:Bang('!UpdateMeasure', 'MeasureGoalTracker')

    -- Restore static task action buttons.
    SKIN:Bang('!ShowMeter', 'AddTask')
    SKIN:Bang('!ShowMeter', 'ClearDone')

    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end


function CloseTaskDetails()

    SKIN:Bang('!HideMeterGroup', 'TaskDeleteView')
    SKIN:Bang('!HideMeterGroup', 'TaskEditView')
    SKIN:Bang('!HideMeterGroup', 'TaskEditedView')
    SKIN:Bang('!SetVariable', 'TaskDetailMode', '0')
    SKIN:Bang('!SetVariable', 'CurrentView', 'Tasks')

    SKIN:Bang('!HideMeterGroup', 'TaskDetailsView')

    SKIN:Bang('!ShowMeterGroup', 'SharedViewport')
    SKIN:Bang('!ShowMeterGroup', 'ViewSelector')

    restoreTaskViewChrome(
        'SYS // READY',
        '#DimColor#'
    )

    SKIN:Bang('!UpdateMeasure', 'MeasureTasks')

    -- Restore static task action buttons.
    SKIN:Bang('!ShowMeter', 'AddTask')
    SKIN:Bang('!ShowMeter', 'ClearDone')

    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end


function FinishTaskWizard()

    -- ==============================================
    -- RESET WIZARD STATE
    -- ==============================================

    SKIN:Bang('!SetVariable', 'TaskConfirm', '0')
    SKIN:Bang('!SetVariable', 'TaskDetailMode', '0')
    SKIN:Bang('!SetVariable', 'WriteMode', '0')
    SKIN:Bang('!SetVariable', 'CurrentView', 'Tasks')
    SKIN:Bang('!SetVariable', 'TaskWizardStep', '0')
    SKIN:Bang('!SetVariable', 'TaskDraft', '')
    SKIN:Bang('!SetVariable', 'TaskType', 'normal')
    SKIN:Bang('!SetVariable', 'TaskWeeklyGoal', '0')
    SKIN:Bang('!SetVariable', 'TaskMonthlyGoal', '0')


    -- ==============================================
    -- HIDE WIZARD / CONFIRMATION UI
    -- ==============================================

    SKIN:Bang('!HideMeterGroup', 'TaskSavedView')
    SKIN:Bang('!HideMeterGroup', 'WriteView')

    SKIN:Bang('!HideMeter', 'GoalInputHint')

    SKIN:Bang('!HideMeter', 'TaskTypeNormalIndicator')
    SKIN:Bang('!HideMeter', 'TaskTypeRepeatIndicator')
    SKIN:Bang('!HideMeter', 'TrackNoneIndicator')
    SKIN:Bang('!HideMeter', 'TrackWeeklyIndicator')
    SKIN:Bang('!HideMeter', 'TrackMonthlyIndicator')
    SKIN:Bang('!HideMeter', 'TrackBothIndicator')

    hideAllScrollControls()

    -- ==============================================
    -- RESTORE TASK VIEW SHELL
    -- ==============================================

    SKIN:Bang('!ShowMeterGroup', 'SharedViewport')
    SKIN:Bang('!ShowMeterGroup', 'ViewSelector')

    SKIN:Bang('!HideMeterGroup', 'NotesView')
    SKIN:Bang('!HideMeterGroup', 'GoalsView')
    SKIN:Bang('!ShowMeterGroup', 'TasksView')


    -- ==============================================
    -- RESTORE ACTIVE TAB
    -- ==============================================

    restoreTaskViewChrome(
        'SYS // READY',
        '#DimColor#'
    )

    -- ==============================================
    -- LET READTASKS CONTROL TASK VISIBILITY
    -- ==============================================

    SKIN:Bang('!UpdateMeasure', 'MeasureTasks')

    SKIN:Bang(
        '!CommandMeasure',
        'MeasureTasks',
        'ScrollBottom()'
    )

    SKIN:Bang('!UpdateMeasure', 'MeasureTasks')

    -- AddTask and ClearDone are static TasksView meters.
    -- ReadTasks.lua only restores the dynamic task rows, so these
    -- must be explicitly shown again after the add-task wizard closes.
    SKIN:Bang('!ShowMeter', 'AddTask')
    SKIN:Bang('!ShowMeter', 'ClearDone')

    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')

end

function ProcessGoalInput(value)

    local step =
        tonumber(
            SKIN:GetVariable('TaskWizardStep')
        ) or 0

    local number =
        positiveInteger(value)


    if not number then

        SKIN:Bang(
            '!SetOption',
            'WriteModeLabel',
            'Text',
            '> ENTER A NUMBER ABOVE 0'
        )

        SKIN:Bang(
            '!UpdateMeter',
            'WriteModeLabel'
        )

        SKIN:Bang('!Redraw')

        return

    end


    -- WEEKLY ONLY
    if step == 3 then

        SKIN:Bang(
            '!SetVariable',
            'TaskWeeklyGoal',
            tostring(number)
        )

        SKIN:Bang(
            '!SetVariable',
            'TaskMonthlyGoal',
            '0'
        )

        SaveRepeatTask()
        return
    end


    -- MONTHLY ONLY
    if step == 4 then

        SKIN:Bang(
            '!SetVariable',
            'TaskWeeklyGoal',
            '0'
        )

        SKIN:Bang(
            '!SetVariable',
            'TaskMonthlyGoal',
            tostring(number)
        )

        SaveRepeatTask()
        return
    end


    -- BOTH: FIRST INPUT = WEEKLY
    if step == 5 then

        SKIN:Bang(
            '!SetVariable',
            'TaskWeeklyGoal',
            tostring(number)
        )

        SKIN:Bang(
            '!SetVariable',
            'TaskWizardStep',
            '6'
        )

        SKIN:Bang(
            '!SetOption',
            'WriteModeLabel',
            'Text',
            '> MONTHLY TARGET'
        )

        SKIN:Bang('!UpdateMeter', '*')
        SKIN:Bang('!Redraw')

        SKIN:Bang(
            '!CommandMeasure',
            'MeasureMonthlyGoalInput',
            'ExecuteBatch ALL'
        )

        return

    end

end

function SaveRepeatTask()

    local task =
        SKIN:GetVariable('TaskDraft')

    local weekly =
        SKIN:GetVariable('TaskWeeklyGoal')

    local monthly =
        SKIN:GetVariable('TaskMonthlyGoal')

    SKIN:Bang(
        '!SetOption',
        'MeasureSaveRepeatTask',
        'Parameter',
        '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "#CURRENTPATH#..\\Scripts\\AddTask.ps1" -Task "' ..
        task ..
        '" -TasksFile "#@#Tasks.txt" -Type "repeat" -WeeklyGoal "' ..
        weekly ..
        '" -MonthlyGoal "' ..
        monthly ..
        '"'
    )

    SKIN:Bang(
        '!UpdateMeasure',
        'MeasureSaveRepeatTask'
    )

    SKIN:Bang(
        '!CommandMeasure',
        'MeasureSaveRepeatTask',
        'Run'
    )

end

function SaveNormalTask()

    local task =
        SKIN:GetVariable('TaskDraft')


    -- ==============================================
    -- CONFIGURE SAVE COMMAND
    -- ==============================================

    SKIN:Bang(
        '!SetOption',
        'MeasureSaveRepeatTask',
        'Parameter',
        '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "#CURRENTPATH#..\\Scripts\\AddTask.ps1" -Task "' ..
        task ..
        '" -TasksFile "#@#Tasks.txt" -Type "normal" -WeeklyGoal "0" -MonthlyGoal "0"'
    )


    -- ==============================================
    -- APPLY UPDATED COMMAND
    -- ==============================================

    SKIN:Bang(
        '!UpdateMeasure',
        'MeasureSaveRepeatTask'
    )


    -- ==============================================
    -- SAVE ASYNCHRONOUSLY
    -- ==============================================

    SKIN:Bang(
        '!CommandMeasure',
        'MeasureSaveRepeatTask',
        'Run'
    )

end

function ProcessMonthlyGoalInput(value)

    local number =
        positiveInteger(value)

    if not number then

        SKIN:Bang(
            '!SetOption',
            'WriteModeLabel',
            'Text',
            '> ENTER A NUMBER ABOVE 0'
        )

        SKIN:Bang(
            '!UpdateMeter',
            'WriteModeLabel'
        )

        SKIN:Bang('!Redraw')

        return

    end


    SKIN:Bang(
        '!SetVariable',
        'TaskMonthlyGoal',
        tostring(number)
    )

    SaveRepeatTask()

end

function ShowTaskSaved()

    local task =
        SKIN:GetVariable('TaskDraft')

    local taskType =
        SKIN:GetVariable('TaskType')

    local weekly =
        tonumber(
            SKIN:GetVariable('TaskWeeklyGoal')
        ) or 0

    local monthly =
        tonumber(
            SKIN:GetVariable('TaskMonthlyGoal')
        ) or 0


    -- ==============================================
    -- BUILD CONFIRMATION DETAILS
    -- ==============================================

    local details =
        buildTaskSummary(
            taskType,
            weekly,
            monthly
        )


    -- ==============================================
    -- REMOVE INPUT UI
    -- ==============================================

    SKIN:Bang('!SetVariable', 'WriteMode', '0')
    SKIN:Bang('!SetVariable', 'TaskConfirm', '1')

    SKIN:Bang('!HideMeterGroup', 'WriteView')
    SKIN:Bang('!HideMeter', 'GoalInputHint')

    SKIN:Bang('!HideMeterGroup', 'SharedViewport')
    SKIN:Bang('!HideMeterGroup', 'ViewSelector')


    -- ==============================================
    -- BUILD CONFIRMATION SCREEN
    -- ==============================================

    SKIN:Bang(
        '!SetOption',
        'TaskSavedName',
        'Text',
        task
    )

    SKIN:Bang(
        '!SetOption',
        'TaskSavedGoals',
        'Text',
        details
    )

    SKIN:Bang(
        '!SetOption',
        'HeaderLabel',
        'Text',
        'DATA // TASK CONFIGURATION'
    )

    SKIN:Bang(
        '!SetOption',
        'HeaderGlow',
        'Text',
        'DATA // TASK CONFIGURATION'
    )

    SKIN:Bang(
        '!SetOption',
        'SystemStatus',
        'Text',
        'SYS // SAVED'
    )

    SKIN:Bang(
        '!SetOption',
        'SystemStatus',
        'FontColor',
        '#AccentColor#'
    )


    -- ==============================================
    -- DISPLAY CONFIRMATION
    -- ==============================================

    SKIN:Bang('!ShowMeterGroup', 'TaskSavedView')

    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')


    -- Return to TASKS is handled by MeasureSaveRepeatTask's
    -- FinishAction after this function returns. This allows
    -- Rainmeter to actually render the confirmation first.

end