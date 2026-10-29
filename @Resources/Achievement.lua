local active = false
local animTick = 0

local tasksPath = nil
local historyPath = nil
local achievementHistoryPath = nil
local badgeHistoryPath = nil
local popupQueue = {}
local popupMode = 'achievement'

local currentFrame = 1
local frameCount = 5
local animationType = 'week'


function Initialize()

    tasksPath = SKIN:GetVariable('@') .. 'Tasks.txt'
    historyPath = SKIN:GetVariable('@') .. 'TaskHistory.txt'
    achievementHistoryPath = SKIN:GetVariable('@') .. 'AchievementHistory.txt'
    badgeHistoryPath = SKIN:GetVariable('@') .. 'BadgeHistory.txt'

end

local function getProgressionThreshold(level)

    if level <= 0 then
        return 0
    end

    local fixed = {
        1,
        5,
        10,
        25,
        50,
        100
    }

    if level <= #fixed then
        return fixed[level]
    end

    return
        100 *
        (2 ^ (level - 6))

end


local function getProgressionLevel(count)

    local level = 0

    while true do

        local nextThreshold =
            getProgressionThreshold(
                level + 1
            )

        if count < nextThreshold then
            break
        end

        level =
            level + 1

    end

    return level

end

local function getAchievementTotals()

    local totals = {
        week = 0,
        month = 0,
        both = 0,
        total = 0
    }

    local file =
        io.open(
            achievementHistoryPath,
            'r'
        )

    if not file then
        return totals
    end

    for line in file:lines() do

        local achievementType =
            string.match(
                line,
                '^([^|]+)|'
            )

        if achievementType == 'week' then

            totals.week =
                totals.week + 1

        elseif achievementType == 'month' then

            totals.month =
                totals.month + 1

        elseif achievementType == 'both' then

            totals.both =
                totals.both + 1

        end

        if achievementType then
            totals.total =
                totals.total + 1
        end

    end

    file:close()

    return totals

end

local function queueLevelUps(
    track,
    previousCount,
    currentCount
)

    local oldLevel =
        getProgressionLevel(
            previousCount
        )

    local newLevel =
        getProgressionLevel(
            currentCount
        )


    if newLevel <= oldLevel then
        return
    end


    for level =
        oldLevel + 1,
        newLevel
    do

        table.insert(
            popupQueue,
            {
                kind = 'level',

                track =
                    track,

                level =
                    level,

                threshold =
                    getProgressionThreshold(
                        level
                    )
            }
        )

    end

end

local function checkProgressionLevelUps(
    achievementType
)

    -- Counts AFTER the new achievement
    -- has already been logged.

    local totals =
        getAchievementTotals()


    -- =========================================
    -- TYPE-SPECIFIC TRACK
    -- =========================================

    if achievementType == 'week' then

        queueLevelUps(
            'WEEKLY',
            math.max(
                0,
                totals.week - 1
            ),
            totals.week
        )


    elseif achievementType == 'month' then

        queueLevelUps(
            'MONTHLY',
            math.max(
                0,
                totals.month - 1
            ),
            totals.month
        )


    elseif achievementType == 'both' then

        queueLevelUps(
            'DUAL',
            math.max(
                0,
                totals.both - 1
            ),
            totals.both
        )

    end


    -- =========================================
    -- TOTAL TRACK
    -- Every achievement advances this.
    -- =========================================

    queueLevelUps(
        'TOTAL',
        math.max(
            0,
            totals.total - 1
        ),
        totals.total
    )

end

-- ==================================================
-- DATE HELPERS
-- ==================================================

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


local function getTodayMidnight()

    local now = os.date('*t')

    return os.time({
        year = now.year,
        month = now.month,
        day = now.day,
        hour = 0,
        min = 0,
        sec = 0
    })

end


local function getWeekStart()

    local now = os.date('*t')
    local daysSinceMonday = (now.wday + 5) % 7

    return getTodayMidnight() - (daysSinceMonday * 86400)

end


local function getMonthStart()

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


-- ==================================================
-- TASK LOOKUP
-- ==================================================

local function getTask(taskId)

    local file = io.open(tasksPath, 'r')

    if not file then
        return nil
    end

    for line in file:lines() do

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

        if tonumber(id) == tonumber(taskId) then

            file:close()

            return {
                id = tonumber(id),
                type = taskType,
                text = text,
                weeklyGoal = tonumber(weeklyGoal) or 0,
                monthlyGoal = tonumber(monthlyGoal) or 0
            }

        end
    end

    file:close()
    return nil

end


-- ==================================================
-- COUNT COMPLETIONS
-- ==================================================

local function getCounts(taskId)

    local weeklyCount = 0
    local monthlyCount = 0

    local weekStart = getWeekStart()
    local monthStart = getMonthStart()
    local now = os.time()

    local file = io.open(historyPath, 'r')

    if not file then
        return 0, 0
    end

    for line in file:lines() do

        local id, timestamp =
            string.match(
                line,
                '^(%d+)|(.+)$'
            )

        if tonumber(id) == tonumber(taskId) then

            local completionTime = parseTimestamp(timestamp)

            if completionTime and completionTime <= now then

                if completionTime >= weekStart then
                    weeklyCount = weeklyCount + 1
                end

                if completionTime >= monthStart then
                    monthlyCount = monthlyCount + 1
                end

            end
        end
    end

    file:close()

    return weeklyCount, monthlyCount

end


-- ==================================================
-- SPRITE HELPERS
-- ==================================================

local function getSpritePath(animType, frame)

    if animType == 'month' then

        return
            '#@#Sprites\\Monthly\\monthly_' ..
            string.format('%02d', frame) ..
            '.png'

    elseif animType == 'both' then

        return
            '#@#Sprites\\Dual\\dual_' ..
            string.format('%02d', frame) ..
            '.png'

    end

    return
        '#@#Sprites\\Weekly\\weekly_' ..
        string.format('%02d', frame) ..
        '.png'

end

local function setSpriteFrame(frame)

    local spritePath =
        getSpritePath(animationType, frame)

    SKIN:Bang(
        '!SetOption',
        'AchievementSprite',
        'ImageName',
        spritePath
    )

    SKIN:Bang(
        '!SetOption',
        'AchievementSpriteGlow',
        'ImageName',
        spritePath
    )

end

-- ==================================================
-- CRT ENTRANCE GLITCH
-- ==================================================

local function playEntranceGlitch()

    -- ------------------------------------------------
    -- FRAME 1
    -- Initial bright flash
    -- ------------------------------------------------

    SKIN:Bang('!ShowMeterGroup', 'AchievementView')

    SKIN:Bang(
        '!SetOption',
        'AchievementBorder',
        'Shape',
        'Rectangle 0,0,296,120,2 | Fill Color 25,80,30,250 | Stroke Color #AccentColor# | StrokeWidth 2'
    )

    SKIN:Bang('!SetOption', 'AchievementTitle', 'X', '30')
    SKIN:Bang('!SetOption', 'AchievementSprite', 'X', '224')
    SKIN:Bang('!SetOption', 'AchievementSpriteGlow', 'X', '226')

    SKIN:Bang('!UpdateMeterGroup', 'AchievementView')
    SKIN:Bang('!Redraw')


    -- ------------------------------------------------
    -- FRAME 2
    -- Signal dropout
    -- ------------------------------------------------

    SKIN:Bang('!Delay', '45')

    SKIN:Bang('!HideMeterGroup', 'AchievementView')
    SKIN:Bang('!Redraw')


    -- ------------------------------------------------
    -- FRAME 3
    -- Return with horizontal glitch
    -- ------------------------------------------------

    SKIN:Bang('!Delay', '35')

    SKIN:Bang('!ShowMeterGroup', 'AchievementView')

    SKIN:Bang('!SetOption', 'AchievementTitle', 'X', '26')
    SKIN:Bang('!SetOption', 'AchievementSprite', 'X', '218')
    SKIN:Bang('!SetOption', 'AchievementSpriteGlow', 'X', '220')

    SKIN:Bang(
        '!SetOption',
        'AchievementBorder',
        'Shape',
        'Rectangle 0,0,296,120,2 | Fill Color 3,10,4,248 | Stroke Color #MutedColor# | StrokeWidth 1'
    )

    SKIN:Bang('!UpdateMeterGroup', 'AchievementView')
    SKIN:Bang('!Redraw')


    -- ------------------------------------------------
    -- FRAME 4
    -- Tiny second flicker
    -- ------------------------------------------------

    SKIN:Bang('!Delay', '55')

    SKIN:Bang('!HideMeter', 'AchievementSprite')
    SKIN:Bang('!HideMeter', 'AchievementTitle')
    SKIN:Bang('!Redraw')


    SKIN:Bang('!Delay', '30')

    SKIN:Bang('!ShowMeter', 'AchievementSprite')
    SKIN:Bang('!ShowMeter', 'AchievementTitle')


    -- ------------------------------------------------
    -- FINAL
    -- Snap everything into proper position
    -- ------------------------------------------------

    SKIN:Bang('!SetOption', 'AchievementTitle', 'X', '28')

    SKIN:Bang('!SetOption', 'AchievementSprite', 'X', '220')
    SKIN:Bang('!SetOption', 'AchievementSpriteGlow', 'X', '222')

    SKIN:Bang(
        '!SetOption',
        'AchievementBorder',
        'Shape',
        'Rectangle 0,0,296,120,2 | Fill Color 3,10,4,248 | Stroke Color #AccentColor# | StrokeWidth 1'
    )

    SKIN:Bang('!UpdateMeterGroup', 'AchievementView')
    SKIN:Bang('!Redraw')

end

local function logAchievement(achievementType, task)

    local file =
        io.open(achievementHistoryPath, 'a')

    if not file then
        return
    end

    local timestamp =
        os.date('%Y-%m-%dT%H:%M:%S')

    file:write(
        achievementType ..
        '|' ..
        tostring(task.id) ..
        '|' ..
        timestamp ..
        '|' ..
        task.text ..
        '\n'
    )

    file:close()

end

local function badgeAlreadyUnlocked(badgeId)

    local file =
        io.open(badgeHistoryPath, 'r')

    if not file then
        return false
    end

    for line in file:lines() do

        local storedId =
            string.match(
                line,
                '^([^|]+)'
            )

        if storedId == badgeId then

            file:close()
            return true

        end

    end

    file:close()

    return false

end


local function unlockBadge(
    badgeId,
    badgeName,
    badgeDescription
    )

    if badgeAlreadyUnlocked(badgeId) then
        return
    end

    local file =
        io.open(badgeHistoryPath, 'a')

    if not file then
        return
    end

    local timestamp =
        os.date('%Y-%m-%dT%H:%M:%S')

    file:write(
        badgeId ..
        '|' ..
        timestamp ..
        '\n'
    )

    file:close()

    table.insert(
        popupQueue,
        {
            kind = 'badge',
            name = badgeName,
            description = badgeDescription
        }
    )

end

local function isHourBetween(startHour, endHour)

    local hour =
        tonumber(
            os.date('%H')
        ) or 0

    return hour >= startHour
        and hour < endHour

end

local function getTodayAchievementCount()

    local count = 0

    local todayStart =
        getTodayMidnight()

    local now =
        os.time()

    local file =
        io.open(
            achievementHistoryPath,
            'r'
        )

    if not file then
        return 0
    end


    for line in file:lines() do

        local timestamp =
            string.match(
                line,
                '^[^|]+|%d+|([^|]+)|'
            )

        if timestamp then

            local timeValue =
                parseTimestamp(timestamp)

            if timeValue
            and timeValue >= todayStart
            and timeValue <= now then

                count =
                    count + 1

            end

        end

    end


    file:close()

    return count

end

local function allWeeklyGoalsMet()

    local foundWeeklyGoal =
        false

    local file =
        io.open(
            tasksPath,
            'r'
        )

    if not file then
        return false
    end


    for line in file:lines() do

        local _,
            taskType,
            id,
            weeklyGoal =
            string.match(
                line,
                '^(%d)|([^|]+)|(%d+)|(%d+)|'
            )

        weeklyGoal =
            tonumber(weeklyGoal) or 0

        id =
            tonumber(id)


        if taskType == 'repeat'
        and weeklyGoal > 0 then

            foundWeeklyGoal =
                true

            local weeklyCount =
                getCounts(id)

            if weeklyCount < weeklyGoal then

                file:close()

                return false

            end

        end

    end


    file:close()

    return foundWeeklyGoal

end

local function checkSpecialBadges()

    local totals =
        getAchievementTotals()


    -- =========================================
    -- FIRST SIGNAL
    -- =========================================

    if totals.total >= 1 then

        unlockBadge(
            'FIRST_SIGNAL',
            'FIRST SIGNAL',
            'ACHIEVEMENT SYSTEM ONLINE'
        )

    end


    -- =========================================
    -- DUAL SYNC
    -- =========================================

    if totals.both >= 1 then

        unlockBadge(
            'DUAL_SYNC',
            'DUAL SYNC',
            'WEEKLY + MONTHLY SYNCHRONIZED'
        )

    end

    -- =========================================
    -- NIGHT OWL
    -- =========================================

    if isHourBetween(0, 5) then

        unlockBadge(
            'NIGHT_OWL',
            'NIGHT OWL',
            'OBJECTIVE CLEARED AFTER MIDNIGHT'
        )

    end

    -- =========================================
    -- EARLY BIRD
    -- =========================================

    if isHourBetween(5, 7) then

        unlockBadge(
            'EARLY_BIRD',
            'EARLY BIRD',
            'OBJECTIVE CLEARED AT DAWN'
        )

    end


    -- =========================================
    -- OVERDRIVE
    -- =========================================

    if getTodayAchievementCount() >= 3 then

        unlockBadge(
            'OVERDRIVE',
            'OVERDRIVE',
            '3 ACHIEVEMENTS CLEARED IN ONE DAY'
        )

    end


    -- =========================================
    -- PERFECT WEEK
    -- =========================================

    if allWeeklyGoalsMet() then

        unlockBadge(
            'PERFECT_WEEK',
            'PERFECT WEEK',
            'ALL WEEKLY OBJECTIVES CLEARED'
        )

    end

end

-- ==================================================
-- SHOW ACHIEVEMENT
-- ==================================================

local function showAchievement(
    achievementType,
    task,
    weeklyCount,
    monthlyCount
)

    logAchievement(
        achievementType,
        task
    )

    checkProgressionLevelUps(
        achievementType
    )

    checkSpecialBadges()

    local title = ''
    local detail = ''

    if achievementType == 'both' then

        title = '> DUAL TARGET ACHIEVED'

        detail =
            'WEEKLY   // ' ..
            weeklyCount ..
            ' / ' ..
            task.weeklyGoal ..
            '\n' ..
            'MONTHLY  // ' ..
            monthlyCount ..
            ' / ' ..
            task.monthlyGoal

    elseif achievementType == 'month' then

        title = '> MONTHLY TARGET ACHIEVED'

        detail =
            'MONTHLY  // ' ..
            monthlyCount ..
            ' / ' ..
            task.monthlyGoal

    else

        title = '> WEEKLY TARGET ACHIEVED'

        detail =
            'WEEKLY   // ' ..
            weeklyCount ..
            ' / ' ..
            task.weeklyGoal

    end


    SKIN:Bang(
        '!SetOption',
        'AchievementTitle',
        'Text',
        title
    )

    SKIN:Bang(
        '!SetOption',
        'AchievementTask',
        'Text',
        string.upper(task.text)
    )

    SKIN:Bang(
        '!SetOption',
        'AchievementProgress',
        'Text',
        detail
    )


    animationType = achievementType
    currentFrame = 1
    animTick = 0
    active = true
    popupMode = 'achievement'

    setSpriteFrame(currentFrame)

    playEntranceGlitch()

    SKIN:Bang(
        '!SetOption',
        'AchievementBorder',
        'Shape',
        'Rectangle 0,0,296,120,2 | Fill Color 3,10,4,248 | Stroke Color #AccentColor# | StrokeWidth 1'
    )

    SKIN:Bang(
        '!SetOption',
        'AchievementTitle',
        'FontColor',
        '#AccentColor#'
    )

    SKIN:Bang(
        '!SetOption',
        'AchievementSprite',
        'Y',
        '95'
    )

    SKIN:Bang(
        '!SetOption',
        'AchievementSpriteGlow',
        'Y',
        '97'
    )

    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')

end


-- ==================================================
-- CHECK NEW COMPLETION
-- ==================================================

function Check(taskId)

    local task = getTask(taskId)

    if not task then
        return
    end

    if task.type ~= 'repeat' then
        return
    end

    local weeklyCount, monthlyCount = getCounts(taskId)

    local weeklyHit =
        task.weeklyGoal > 0
        and weeklyCount == task.weeklyGoal

    local monthlyHit =
        task.monthlyGoal > 0
        and monthlyCount == task.monthlyGoal


    if weeklyHit and monthlyHit then

        showAchievement(
            'both',
            task,
            weeklyCount,
            monthlyCount
        )

    elseif monthlyHit then

        showAchievement(
            'month',
            task,
            weeklyCount,
            monthlyCount
        )

    elseif weeklyHit then

        showAchievement(
            'week',
            task,
            weeklyCount,
            monthlyCount
        )

    end

end

local function showNextQueuedPopup()

    if #popupQueue == 0 then

        popupMode =
            'achievement'

        active =
            false

        SKIN:Bang(
            '!HideMeterGroup',
            'AchievementView'
        )

        SKIN:Bang(
            '!UpdateMeter',
            '*'
        )

        SKIN:Bang(
            '!Redraw'
        )

        return
    end


    local popup =
        table.remove(
            popupQueue,
            1
        )


    animTick = 0
    active = true


    -- =========================================
    -- LEVEL-UP POPUP
    -- =========================================

    if popup.kind == 'level' then

        popupMode = 'level'


        SKIN:Bang(
            '!SetOption',
            'AchievementCode',
            'Text',
            'SYS // LEVEL INCREASED'
        )


        SKIN:Bang(
            '!SetOption',
            'AchievementTitle',
            'Text',
            '> ' ..
            popup.track ..
            ' // LV. ' ..
            tostring(
                popup.level
            )
        )


        SKIN:Bang(
            '!SetOption',
            'AchievementTask',
            'Text',
            tostring(
                popup.threshold
            ) ..
            ' TARGETS CLEARED'
        )


        SKIN:Bang(
            '!SetOption',
            'AchievementProgress',
            'Text',
            'PROGRESSION // UPDATED'
        )


        SKIN:Bang(
            '!SetOption',
            'AchievementCleared',
            'Text',
            '[ OK ] LEVEL REGISTERED'
        )


    -- =========================================
    -- SPECIAL BADGE POPUP
    -- =========================================

    else

        popupMode = 'badge'


        SKIN:Bang(
            '!SetOption',
            'AchievementCode',
            'Text',
            'SYS // BADGE UNLOCKED'
        )


        SKIN:Bang(
            '!SetOption',
            'AchievementTitle',
            'Text',
            '> ' ..
            popup.name
        )


        SKIN:Bang(
            '!SetOption',
            'AchievementTask',
            'Text',
            popup.description
        )


        SKIN:Bang(
            '!SetOption',
            'AchievementProgress',
            'Text',
            'MILESTONE // REGISTERED'
        )


        SKIN:Bang(
            '!SetOption',
            'AchievementCleared',
            'Text',
            '[ OK ] UNLOCK CONFIRMED'
        )

    end


    -- =========================================
    -- SHARED CELEBRATION VISUAL
    -- =========================================

    animationType = 'both'
    currentFrame = 5

    setSpriteFrame(5)


    SKIN:Bang(
        '!SetOption',
        'AchievementTitle',
        'FontColor',
        '#AccentColor#'
    )


    SKIN:Bang(
        '!SetOption',
        'AchievementBorder',
        'Shape',
        'Rectangle 0,0,296,120,2 | Fill Color 3,10,4,248 | Stroke Color #AccentColor# | StrokeWidth 2'
    )


    SKIN:Bang(
        '!ShowMeterGroup',
        'AchievementView'
    )


    SKIN:Bang(
        '!UpdateMeterGroup',
        'AchievementView'
    )

    SKIN:Bang('!Redraw')

end

-- ==================================================
-- ANIMATION
-- ==================================================

function Update()

    if not active then
        return 0
    end

    animTick = animTick + 1

    -- ==================================================
    -- BADGE POPUP MODE
    -- ==================================================

    if popupMode == 'badge' or popupMode == 'level' then

        -- subtle terminal pulse

        if animTick % 2 == 1 then

            SKIN:Bang(
                '!SetOption',
                'AchievementBorder',
                'Shape',
                'Rectangle 0,0,296,120,2 | Fill Color 3,10,4,248 | Stroke Color #AccentColor# | StrokeWidth 2'
            )

            SKIN:Bang(
                '!SetOption',
                'AchievementTitle',
                'FontColor',
                '#AccentColor#'
            )

        else

            SKIN:Bang(
                '!SetOption',
                'AchievementBorder',
                'Shape',
                'Rectangle 0,0,296,120,2 | Fill Color 3,10,4,248 | Stroke Color #MutedColor# | StrokeWidth 1'
            )

            SKIN:Bang(
                '!SetOption',
                'AchievementTitle',
                'FontColor',
                '#TextColor#'
            )

        end


        -- hold badge for a few ticks

        if animTick >= 5 then

            showNextQueuedPopup()

            return 0

        end


        SKIN:Bang(
            '!UpdateMeterGroup',
            'AchievementView'
        )

        SKIN:Bang('!Redraw')

        return animTick

    end

    -- sprite frame progression
    if animTick <= frameCount then
        currentFrame = animTick
    else
        currentFrame = frameCount
    end

    setSpriteFrame(currentFrame)

    -- slight bobbing
    if animTick % 2 == 1 then

        SKIN:Bang('!SetOption', 'AchievementSprite', 'Y', '94')
        SKIN:Bang('!SetOption', 'AchievementSpriteGlow', 'Y', '96')

        SKIN:Bang(
            '!SetOption',
            'AchievementBorder',
            'Shape',
            'Rectangle 0,0,296,120,2 | Fill Color 3,10,4,248 | Stroke Color #AccentColor# | StrokeWidth 2'
        )

        SKIN:Bang(
            '!SetOption',
            'AchievementTitle',
            'FontColor',
            '#AccentColor#'
        )

    else

        SKIN:Bang('!SetOption', 'AchievementSprite', 'Y', '94')
        SKIN:Bang('!SetOption', 'AchievementSpriteGlow', 'Y', '96')

        SKIN:Bang(
            '!SetOption',
            'AchievementBorder',
            'Shape',
            'Rectangle 0,0,296,120,2 | Fill Color 3,10,4,248 | Stroke Color #MutedColor# | StrokeWidth 1'
        )

        SKIN:Bang(
            '!SetOption',
            'AchievementTitle',
            'FontColor',
            '#TextColor#'
        )

    end

    -- dismiss after animation finishes
    if animTick >= 8 then

        if #popupQueue > 0 then

        showNextQueuedPopup()

    else

        Dismiss()

    end

        return 0

    end

    SKIN:Bang('!UpdateMeterGroup', 'AchievementView')
    SKIN:Bang('!Redraw')

    return animTick

end


function Dismiss()

    active = false
    animTick = 0
    currentFrame = 1
    popupMode = 'achievement'

    SKIN:Bang(
        '!HideMeterGroup',
        'AchievementView'
    )

    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')

end