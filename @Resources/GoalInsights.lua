local historyEntries = {}
local historyOffset = 0
local visibleHistoryLines = 5

local tasksPath = nil
local historyPath = nil
local achievementHistoryPath = nil
local badgeHistoryPath = nil

local badgeDetailReturnView = 'GoalBadges'


function Initialize()

    tasksPath =
        SKIN:GetVariable('@') .. 'Tasks.txt'

    historyPath =
        SKIN:GetVariable('@') .. 'TaskHistory.txt'

    achievementHistoryPath =
        SKIN:GetVariable('@') .. 'AchievementHistory.txt'

    badgeHistoryPath =
        SKIN:GetVariable('@') .. 'BadgeHistory.txt'

end


-- ==================================================
-- HELPERS
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


local function midnight(timeValue)

    local t = os.date('*t', timeValue)

    return os.time({
        year = t.year,
        month = t.month,
        day = t.day,
        hour = 0,
        min = 0,
        sec = 0
    })
end


local function getWeekStart(now)

    local t = os.date('*t', now)
    local daysSinceMonday = (t.wday + 5) % 7

    return midnight(now) - (daysSinceMonday * 86400)
end


local function getMonthStart(now)

    local t = os.date('*t', now)

    return os.time({
        year = t.year,
        month = t.month,
        day = 1,
        hour = 0,
        min = 0,
        sec = 0
    })
end


local function loadGoalTasks()

    local byId = {}
    local ordered = {}

    local file = io.open(tasksPath, 'r')

    if not file then
        return byId, ordered
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

        if taskType == 'repeat' then

            weeklyGoal = tonumber(weeklyGoal) or 0
            monthlyGoal = tonumber(monthlyGoal) or 0

            if weeklyGoal > 0 or monthlyGoal > 0 then

                local task = {
                    id = tonumber(id),
                    text = text,
                    weeklyGoal = weeklyGoal,
                    monthlyGoal = monthlyGoal
                }

                byId[task.id] = task
                table.insert(ordered, task)
            end
        end
    end

    file:close()

    table.sort(ordered, function(a, b)
        return a.id < b.id
    end)

    return byId, ordered
end


local function loadHistoryEntries()

    historyEntries = {}

    local byId = loadGoalTasks()

    local file = io.open(historyPath, 'r')

    if not file then
        return
    end

    for line in file:lines() do

        local id, timestamp =
            string.match(line, '^(%d+)|(.+)$')

        id = tonumber(id)

        local task = byId[id]
        local timeValue = parseTimestamp(timestamp or '')

        if task and timeValue then

            table.insert(historyEntries, {
                id = id,
                text = task.text,
                timestamp = timestamp,
                timeValue = timeValue
            })
        end
    end

    file:close()

    table.sort(historyEntries, function(a, b)
        return a.timeValue > b.timeValue
    end)
end


local function historyMaxOffset()
    return math.max(0, #historyEntries - visibleHistoryLines)
end


local function clampHistoryOffset()

    local maxOffset = historyMaxOffset()

    if historyOffset < 0 then
        historyOffset = 0
    elseif historyOffset > maxOffset then
        historyOffset = maxOffset
    end
end


local function dayLabel(timeValue)

    local now = os.time()
    local today = midnight(now)
    local eventDay = midnight(timeValue)

    if eventDay == today then
        return 'TODAY'
    elseif eventDay == today - 86400 then
        return 'YDAY'
    end

    return string.upper(os.date('%b %d', timeValue))
end


local function hideHistoryLines()

    for slot = 1, visibleHistoryLines do
        SKIN:Bang('!HideMeter', 'GoalHistoryLine' .. slot)
    end

    SKIN:Bang('!HideMeter', 'GoalHistoryEmpty')
    SKIN:Bang('!HideMeter', 'GoalHistoryUp')
    SKIN:Bang('!HideMeter', 'GoalHistoryDown')

    SKIN:Bang('!HideMeter', 'GoalHistoryScrollRail')
    SKIN:Bang('!HideMeter', 'GoalHistoryScrollThumb')
    SKIN:Bang('!HideMeter', 'GoalHistoryScrollThumbGlow')
end


local function drawHistory()

    loadHistoryEntries()
    clampHistoryOffset()

    if #historyEntries == 0 then

        for slot = 1, visibleHistoryLines do
            SKIN:Bang('!HideMeter', 'GoalHistoryLine' .. slot)
        end

        SKIN:Bang('!ShowMeter', 'GoalHistoryEmpty')
        SKIN:Bang('!HideMeter', 'GoalHistoryUp')
        SKIN:Bang('!HideMeter', 'GoalHistoryDown')

        SKIN:Bang('!UpdateMeter', '*')
        SKIN:Bang('!Redraw')
        return
    end

    SKIN:Bang('!HideMeter', 'GoalHistoryEmpty')

    for slot = 1, visibleHistoryLines do

        local entry =
            historyEntries[historyOffset + slot]

        local meter =
            'GoalHistoryLine' .. slot

        if entry then

            local text =
                dayLabel(entry.timeValue) ..
                '  ' ..
                os.date('%H:%M', entry.timeValue) ..
                '  +1  ' ..
                string.upper(entry.text)

            SKIN:Bang(
                '!SetOption',
                meter,
                'Text',
                text
            )

            SKIN:Bang('!ShowMeter', meter)

        else

            SKIN:Bang('!HideMeter', meter)

        end
    end

    local maxOffset = historyMaxOffset()

        if maxOffset > 0 then

        SKIN:Bang('!ShowMeter', 'GoalHistoryScrollRail')
        SKIN:Bang('!ShowMeter', 'GoalHistoryScrollThumbGlow')
        SKIN:Bang('!ShowMeter', 'GoalHistoryScrollThumb')

        local topY = 80
        local bottomY = 160
        local travel = bottomY - topY

        local thumbY = topY

        if maxOffset > 0 then
            thumbY = topY + math.floor(
                (historyOffset / maxOffset) * travel
            )
        end

        SKIN:Bang(
            '!SetOption',
            'GoalHistoryScrollThumb',
            'Y',
            tostring(thumbY)
        )

        SKIN:Bang(
            '!SetOption',
            'GoalHistoryScrollThumbGlow',
            'Y',
            tostring(thumbY - 1)
        )

    else

        SKIN:Bang('!HideMeter', 'GoalHistoryScrollRail')
        SKIN:Bang('!HideMeter', 'GoalHistoryScrollThumbGlow')
        SKIN:Bang('!HideMeter', 'GoalHistoryScrollThumb')

    end

    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end


-- ==================================================
-- HISTORY VIEW
-- ==================================================

function ShowHistory()

    historyOffset = 0

    SKIN:Bang('!SetVariable', 'CurrentView', 'GoalHistory')

    SKIN:Bang('!HideMeterGroup', 'GoalsView')
    SKIN:Bang('!HideMeterGroup', 'GoalStatsView')
    SKIN:Bang('!HideMeterGroup', 'ViewSelector')

    SKIN:Bang('!ShowMeterGroup', 'SharedViewport')
    SKIN:Bang('!ShowMeterGroup', 'GoalHistoryView')

    SKIN:Bang(
        '!SetOption',
        'HeaderLabel',
        'Text',
        'DATA // GOAL HISTORY'
    )

    SKIN:Bang(
        '!SetOption',
        'HeaderGlow',
        'Text',
        'DATA // GOAL HISTORY'
    )

    SKIN:Bang(
        '!SetOption',
        'SystemStatus',
        'Text',
        'SYS // ACTIVITY LOG'
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
        'LOG: COMPLETIONS'
    )

    drawHistory()
end


function HistoryScrollUp()

    historyOffset = historyOffset - 1
    clampHistoryOffset()
    drawHistory()
end


function HistoryScrollDown()

    historyOffset = historyOffset + 1
    clampHistoryOffset()
    drawHistory()
end


-- ==================================================
-- STATS
-- ==================================================

local function calculateStats()

    local byId, ordered = loadGoalTasks()

    local now = os.time()
    local todayStart = midnight(now)
    local weekStart = getWeekStart(now)
    local monthStart = getMonthStart(now)

    local todayCount = 0
    local weekCount = 0
    local monthCount = 0

    local taskWeek = {}
    local taskMonth = {}

    local file = io.open(historyPath, 'r')

    if file then

        for line in file:lines() do

            local id, timestamp =
                string.match(line, '^(%d+)|(.+)$')

            id = tonumber(id)

            local task = byId[id]
            local timeValue = parseTimestamp(timestamp or '')

            if task and timeValue and timeValue <= now then

                if timeValue >= todayStart then
                    todayCount = todayCount + 1
                end

                if timeValue >= weekStart then
                    weekCount = weekCount + 1
                    taskWeek[id] = (taskWeek[id] or 0) + 1
                end

                if timeValue >= monthStart then
                    monthCount = monthCount + 1
                    taskMonth[id] = (taskMonth[id] or 0) + 1
                end
            end
        end

        file:close()
    end

    local weeklyMet = 0
    local weeklyTotal = 0
    local monthlyMet = 0
    local monthlyTotal = 0

    local topTask = nil
    local topCount = 0

    for _, task in ipairs(ordered) do

        if task.weeklyGoal > 0 then

            weeklyTotal = weeklyTotal + 1

            if (taskWeek[task.id] or 0) >= task.weeklyGoal then
                weeklyMet = weeklyMet + 1
            end
        end

        if task.monthlyGoal > 0 then

            monthlyTotal = monthlyTotal + 1

            if (taskMonth[task.id] or 0) >= task.monthlyGoal then
                monthlyMet = monthlyMet + 1
            end
        end

        local count = taskMonth[task.id] or 0

        if count > topCount then
            topCount = count
            topTask = task.text
        end
    end

    return {
        today = todayCount,
        week = weekCount,
        month = monthCount,
        weeklyMet = weeklyMet,
        weeklyTotal = weeklyTotal,
        monthlyMet = monthlyMet,
        monthlyTotal = monthlyTotal,
        topTask = topTask,
        topCount = topCount
    }
end


local function drawStats()

    local stats = calculateStats()

    SKIN:Bang(
        '!SetOption',
        'GoalStatsTodayValue',
        'Text',
        tostring(stats.today)
    )

    SKIN:Bang(
        '!SetOption',
        'GoalStatsWeekValue',
        'Text',
        tostring(stats.week)
    )

    SKIN:Bang(
        '!SetOption',
        'GoalStatsMonthValue',
        'Text',
        tostring(stats.month)
    )

    SKIN:Bang(
        '!SetOption',
        'GoalStatsWeekMetValue',
        'Text',
        stats.weeklyMet .. ' / ' .. stats.weeklyTotal
    )

    SKIN:Bang(
        '!SetOption',
        'GoalStatsMonthMetValue',
        'Text',
        stats.monthlyMet .. ' / ' .. stats.monthlyTotal
    )

    local topText = '--'

    if stats.topTask and stats.topCount > 0 then
        topText =
            string.upper(stats.topTask) ..
            ' // ' ..
            tostring(stats.topCount)
    end

    SKIN:Bang(
        '!SetOption',
        'GoalStatsTopValue',
        'Text',
        topText
    )

    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end


function ShowStats()

    SKIN:Bang('!SetVariable', 'CurrentView', 'GoalStats')

    SKIN:Bang('!HideMeterGroup', 'GoalsView')
    SKIN:Bang('!HideMeterGroup', 'GoalHistoryView')
    SKIN:Bang('!HideMeterGroup', 'ViewSelector')

    SKIN:Bang('!ShowMeterGroup', 'SharedViewport')
    SKIN:Bang('!ShowMeterGroup', 'GoalStatsView')

    SKIN:Bang(
        '!SetOption',
        'HeaderLabel',
        'Text',
        'DATA // GOAL STATS'
    )

    SKIN:Bang(
        '!SetOption',
        'HeaderGlow',
        'Text',
        'DATA // GOAL STATS'
    )

    SKIN:Bang(
        '!SetOption',
        'SystemStatus',
        'Text',
        'SYS // ANALYTICS'
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
        'ANALYTICS: ACTIVE'
    )

    drawStats()
end

local progressionTracks = {

    WEEKLY = {
        stat = 'week',
        name = 'WEEKLY'
    },

    MONTHLY = {
        stat = 'month',
        name = 'MONTHLY'
    },

    DUAL = {
        stat = 'both',
        name = 'DUAL'
    },

    TOTAL = {
        stat = 'total',
        name = 'TOTAL'
    }

}


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

    -- after level 6:
    -- 200, 400, 800, 1600...
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

local function getTrackData(
    trackId,
    stats
)

    local track =
        progressionTracks[trackId]

    if not track then
        return nil
    end

    local count =
        stats[track.stat] or 0

    local level =
        getProgressionLevel(count)

    local currentThreshold =
        getProgressionThreshold(level)

    local nextThreshold =
        getProgressionThreshold(
            level + 1
        )

    return {
        id = trackId,
        name = track.name,
        count = count,
        level = level,
        currentThreshold =
            currentThreshold,
        nextThreshold =
            nextThreshold
    }

end

local badgeDefinitions = {

    FIRST_SIGNAL = {

        name =
            'FIRST SIGNAL',

        badgeType =
            'SPECIAL',

        description =
            'ACHIEVEMENT SYSTEM ONLINE',

        requirement =
            'UNLOCK ANY ACHIEVEMENT'

    },

    DUAL_SYNC = {

        name =
            'DUAL SYNC',

        badgeType =
            'SPECIAL',

        description =
            'WEEKLY + MONTHLY SYNCHRONIZED',

        requirement =
            'CLEAR A DUAL TARGET'

    },

    NIGHT_OWL = {

        name =
            'NIGHT OWL',

        badgeType =
            'SECRET',

        description =
            'OBJECTIVE CLEARED AFTER MIDNIGHT',

        requirement =
            'CLEAR A GOAL BETWEEN 00:00 AND 04:59'

    },

    EARLY_BIRD = {

        name =
            'EARLY BIRD',

        badgeType =
            'SECRET',

        description =
            'OBJECTIVE CLEARED AT DAWN',

        requirement =
            'CLEAR A GOAL BETWEEN 05:00 AND 06:59'

    },

    OVERDRIVE = {

        name =
            'OVERDRIVE',

        badgeType =
            'SECRET',

        description =
            'MULTIPLE TARGETS CLEARED IN RAPID SUCCESSION',

        requirement =
            'CLEAR 3 ACHIEVEMENTS IN ONE DAY'

    },

    PERFECT_WEEK = {

        name =
            'PERFECT WEEK',

        badgeType =
            'SECRET',

        description =
            'ALL WEEKLY OBJECTIVES CLEARED',

        requirement =
            'COMPLETE EVERY ACTIVE WEEKLY GOAL'

    },

}

local specialBadgeIds = {
    'FIRST_SIGNAL',
    'DUAL_SYNC',
    'NIGHT_OWL',
    'EARLY_BIRD',
    'OVERDRIVE',
    'PERFECT_WEEK'
}

local function loadBadgeUnlocks()

    local unlocks = {}

    local file =
        io.open(badgeHistoryPath, 'r')

    if not file then
        return unlocks
    end

    for line in file:lines() do

        local badgeId,
              timestamp =
            string.match(
                line,
                '^([^|]+)|?(.*)$'
            )

        if badgeId and badgeId ~= '' then

            unlocks[badgeId] = {
                timestamp =
                    timestamp ~= ''
                    and timestamp
                    or nil
            }

        end

    end

    file:close()

    return unlocks

end

-- ==================================================
-- BADGES / ACHIEVEMENTS
-- ==================================================

local function loadAchievementStats()

    local stats = {
        week = 0,
        month = 0,
        both = 0,
        total = 0
    }

    local file =
        io.open(achievementHistoryPath, 'r')

    if not file then
        return stats
    end

    for line in file:lines() do

        local achievementType =
        string.match(
            line,
            '^([^|]+)|'
        )

        if achievementType then

            if achievementType == 'week' then

                stats.week =
                    stats.week + 1

            elseif achievementType == 'month' then

                stats.month =
                    stats.month + 1

            elseif achievementType == 'both' then

                stats.both =
                    stats.both + 1

            end

            stats.total =
                stats.total + 1

        end

    end

    file:close()

    return stats

end

local function levelLabel(level)

    if level <= 0 then
        return '--'
    end

    return
        'LV. ' ..
        tostring(level)

end

local function drawBadges()

    local stats =
        loadAchievementStats()

    local weekly =
        getTrackData(
            'WEEKLY',
            stats
    )

    local monthly =
        getTrackData(
            'MONTHLY',
            stats
    )

    local dual =
        getTrackData(
            'DUAL',
            stats
    )

    local total =
        getTrackData(
            'TOTAL',
            stats
    )


    SKIN:Bang(
        '!SetOption',
        'GoalTrackWeeklyLevel',
        'Text',
        levelLabel(weekly.level)
    )

    SKIN:Bang(
        '!SetOption',
        'GoalTrackMonthlyLevel',
        'Text',
        levelLabel(monthly.level)
    )

    SKIN:Bang(
        '!SetOption',
        'GoalTrackDualLevel',
        'Text',
        levelLabel(dual.level)
    )

    SKIN:Bang(
        '!SetOption',
        'GoalTrackTotalLevel',
        'Text',
        levelLabel(total.level)
    )

    local unlocks =
    loadBadgeUnlocks()

    local specialCount = 0

    for _, badgeId in ipairs(specialBadgeIds) do

        if unlocks[badgeId] then
            specialCount =
                specialCount + 1
        end

    end

    SKIN:Bang(
        '!SetOption',
        'GoalBadgesUnlocked',
        'Text',
        'SPECIAL // ' ..
        tostring(specialCount) ..
        ' / ' ..
        tostring(#specialBadgeIds)
    )

    SKIN:Bang(
        '!SetOption',
        'GoalBadgesSummary',
        'Text',
        'WEEK ' ..
        tostring(stats.week) ..
        '   //   MONTH ' ..
        tostring(stats.month) ..
        '   //   DUAL ' ..
        tostring(stats.both)
    )

    SKIN:Bang(
        '!UpdateMeterGroup',
        'GoalBadgesView'
    )

    SKIN:Bang('!Redraw')

end

function ShowBadges()

    SKIN:Bang(
        '!SetVariable',
        'CurrentView',
        'GoalBadges'
    )

    SKIN:Bang(
        '!HideMeterGroup',
        'SpecialBadgesView'
    )

    SKIN:Bang(
        '!HideMeterGroup',
        'BadgeDetailView'
    )

    SKIN:Bang(
        '!HideMeterGroup',
        'GoalsView'
    )

    SKIN:Bang(
        '!HideMeterGroup',
        'GoalHistoryView'
    )

    SKIN:Bang(
        '!HideMeterGroup',
        'GoalStatsView'
    )

    SKIN:Bang(
        '!HideMeterGroup',
        'ViewSelector'
    )

    SKIN:Bang(
        '!ShowMeterGroup',
        'SharedViewport'
    )

    SKIN:Bang(
        '!ShowMeterGroup',
        'GoalBadgesView'
    )


    SKIN:Bang(
        '!SetOption',
        'HeaderLabel',
        'Text',
        'DATA // ACHIEVEMENTS'
    )

    SKIN:Bang(
        '!SetOption',
        'HeaderGlow',
        'Text',
        'DATA // ACHIEVEMENTS'
    )

    SKIN:Bang(
        '!SetOption',
        'SystemStatus',
        'Text',
        'SYS // RECORD'
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
        'BADGES: ACTIVE'
    )

    drawBadges()

end

local function drawSpecialBadges()

    local unlocks =
        loadBadgeUnlocks()


    local firstUnlocked =
        unlocks['FIRST_SIGNAL'] ~= nil

    local dualUnlocked =
        unlocks['DUAL_SYNC'] ~= nil

    local nightOwlUnlocked =
        unlocks['NIGHT_OWL'] ~= nil

    local earlyBirdUnlocked =
        unlocks['EARLY_BIRD'] ~= nil
    
    local overdriveUnlocked =
        unlocks['OVERDRIVE'] ~= nil

    local perfectWeekUnlocked =
        unlocks['PERFECT_WEEK'] ~= nil

    if nightOwlUnlocked then

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgeNightOwl',
            'Text',
            'NIGHT OWL'
        )

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgeNightOwl',
            'FontColor',
            '#TextColor#'
        )

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgeNightOwlStatus',
            'Text',
            'UNLOCKED'
        )

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgeNightOwlStatus',
            'FontColor',
            '#AccentColor#'
        )

    else

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgeNightOwl',
            'Text',
            '? ? ?'
        )

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgeNightOwl',
            'FontColor',
            '#DimColor#'
        )

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgeNightOwlStatus',
            'Text',
            'UNKNOWN'
        )

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgeNightOwlStatus',
            'FontColor',
            '#DimColor#'
        )

    end

    if earlyBirdUnlocked then

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgeEarlyBird',
            'Text',
            'EARLY BIRD'
        )

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgeEarlyBird',
            'FontColor',
            '#TextColor#'
        )

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgeEarlyBirdStatus',
            'Text',
            'UNLOCKED'
        )

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgeEarlyBirdStatus',
            'FontColor',
            '#AccentColor#'
        )

    else

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgeEarlyBird',
            'Text',
            '? ? ?'
        )

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgeEarlyBird',
            'FontColor',
            '#DimColor#'
        )

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgeEarlyBirdStatus',
            'Text',
            'UNKNOWN'
        )

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgeEarlyBirdStatus',
            'FontColor',
            '#DimColor#'
        )

    end

    if overdriveUnlocked then

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgeOverdrive',
            'Text',
            'OVERDRIVE'
        )

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgeOverdrive',
            'FontColor',
            '#TextColor#'
        )

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgeOverdriveStatus',
            'Text',
            'UNLOCKED'
        )

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgeOverdriveStatus',
            'FontColor',
            '#AccentColor#'
        )

    else

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgeOverdrive',
            'Text',
            '? ? ?'
        )

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgeOverdrive',
            'FontColor',
            '#DimColor#'
        )

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgeOverdriveStatus',
            'Text',
            'UNKNOWN'
        )

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgeOverdriveStatus',
            'FontColor',
            '#DimColor#'
        )

    end

    if perfectWeekUnlocked then

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgePerfectWeek',
            'Text',
            'PERFECT WEEK'
        )

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgePerfectWeek',
            'FontColor',
            '#TextColor#'
        )

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgePerfectWeekStatus',
            'Text',
            'UNLOCKED'
        )

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgePerfectWeekStatus',
            'FontColor',
            '#AccentColor#'
        )

    else

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgePerfectWeek',
            'Text',
            '? ? ?'
        )

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgePerfectWeek',
            'FontColor',
            '#DimColor#'
        )

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgePerfectWeekStatus',
            'Text',
            'UNKNOWN'
        )

        SKIN:Bang(
            '!SetOption',
            'SpecialBadgePerfectWeekStatus',
            'FontColor',
            '#DimColor#'
        )

    end

    SKIN:Bang(
        '!SetOption',
        'SpecialBadge1Status',
        'Text',
        firstUnlocked
        and 'UNLOCKED'
        or 'LOCKED'
    )

    SKIN:Bang(
        '!SetOption',
        'SpecialBadge1Status',
        'FontColor',
        firstUnlocked
        and '#AccentColor#'
        or '#DimColor#'
    )


    SKIN:Bang(
        '!SetOption',
        'SpecialBadge2Status',
        'Text',
        dualUnlocked
        and 'UNLOCKED'
        or 'LOCKED'
    )

    SKIN:Bang(
        '!SetOption',
        'SpecialBadge2Status',
        'FontColor',
        dualUnlocked
        and '#AccentColor#'
        or '#DimColor#'
    )


    SKIN:Bang(
        '!UpdateMeterGroup',
        'SpecialBadgesView'
    )

    SKIN:Bang('!Redraw')

end

function ShowSpecialBadges()

    SKIN:Bang(
        '!SetVariable',
        'CurrentView',
        'SpecialBadges'
    )

    SKIN:Bang(
        '!HideMeterGroup',
        'GoalBadgesView'
    )

    SKIN:Bang(
        '!HideMeterGroup',
        'BadgeDetailView'
    )

    SKIN:Bang(
        '!ShowMeterGroup',
        'SpecialBadgesView'
    )


    SKIN:Bang(
        '!SetOption',
        'HeaderLabel',
        'Text',
        'DATA // SPECIAL BADGES'
    )

    SKIN:Bang(
        '!SetOption',
        'HeaderGlow',
        'Text',
        'DATA // SPECIAL BADGES'
    )

    SKIN:Bang(
        '!SetOption',
        'SystemStatus',
        'Text',
        'SYS // ARCHIVE'
    )

    SKIN:Bang(
        '!SetOption',
        'FooterLeft',
        'Text',
        'SPECIAL: RECORD'
    )


    drawSpecialBadges()

end

function ShowBadgeDetails(badgeId)

    local badge =
        badgeDefinitions[badgeId]

    if not badge then
        return
    end

    local unlocks =
        loadBadgeUnlocks()

    local unlocked =
        unlocks[badgeId] ~= nil


    local current =
        unlocked and 1 or 0

    local required = 1


    local fillWidth =
        unlocked and 260 or 0

    local glowWidth =
        unlocked and 262 or 0

    SKIN:Bang(
        '!SetOption',
        'BadgeTrackRail',
        'Shape',
        'Rectangle 0,0,260,5 | Fill Color #DimColor# | StrokeWidth 0'
    )

    SKIN:Bang(
        '!SetOption',
        'BadgeTrackFill',
        'Shape',
        'Rectangle 0,0,' ..
        tostring(fillWidth) ..
        ',5 | Fill Color #AccentColor# | StrokeWidth 0'
    )

    SKIN:Bang(
        '!SetOption',
        'BadgeTrackFillGlow',
        'Shape',
        'Rectangle 0,0,' ..
        tostring(glowWidth) ..
        ',7 | Fill Color #GlowStrong# | StrokeWidth 0'
    )

    SKIN:Bang('!ShowMeter', 'BadgeTrackRail')
    SKIN:Bang('!ShowMeter', 'BadgeTrackFill')
    SKIN:Bang('!ShowMeter', 'BadgeTrackFillGlow')

    -- =========================================
    -- NAME
    -- =========================================

    SKIN:Bang(
        '!SetOption',
        'BadgeDetailName',
        'Text',
        '> ' .. badge.name
    )


    -- =========================================
    -- TYPE
    -- =========================================

    SKIN:Bang(
        '!SetOption',
        'BadgeDetailType',
        'Text',
        'TYPE // ' ..
        badge.badgeType
    )


    -- =========================================
    -- DESCRIPTION
    -- =========================================

    SKIN:Bang(
        '!SetOption',
        'BadgeDetailDescription',
        'Text',
        badge.description
    )


    -- =========================================
    -- STATUS
    -- =========================================

    if unlocked then

        SKIN:Bang(
            '!SetOption',
            'BadgeDetailStatus',
            'Text',
            'STATUS // UNLOCKED'
        )

        SKIN:Bang(
            '!SetOption',
            'BadgeDetailStatus',
            'FontColor',
            '#AccentColor#'
        )

    else

        SKIN:Bang(
            '!SetOption',
            'BadgeDetailStatus',
            'Text',
            'STATUS // LOCKED'
        )

        SKIN:Bang(
            '!SetOption',
            'BadgeDetailStatus',
            'FontColor',
            '#DimColor#'
        )

    end


    -- =========================================
    -- REQUIREMENT / PROGRESS
    -- =========================================

    SKIN:Bang(
        '!SetOption',
        'BadgeDetailRequirement',
        'Text',
        'REQUIREMENT // ' ..
        badge.requirement
    )

    SKIN:Bang(
        '!SetOption',
        'BadgeDetailProgress',
        'Text',
        'PROGRESS // ' ..
        tostring(
            math.min(
                current,
                required
            )
        ) ..
        ' / ' ..
        tostring(required)
    )


    -- =========================================
    -- UNLOCK DATE
    -- =========================================

    local dateText =
        'UNLOCKED // --'

    if unlocked
    and unlocks[badgeId].timestamp then

        local timeValue =
            parseTimestamp(
                unlocks[badgeId].timestamp
            )

        if timeValue then

            dateText =
                'UNLOCKED // ' ..
                string.upper(
                    os.date(
                        '%b %d, %Y',
                        timeValue
                    )
                )

        end

    end


    SKIN:Bang(
        '!SetOption',
        'BadgeDetailDate',
        'Text',
        dateText
    )

        local currentView =
        SKIN:GetVariable('CurrentView')

    if currentView == 'SpecialBadges' then
        badgeDetailReturnView = 'SpecialBadges'
    else
        badgeDetailReturnView = 'GoalBadges'
    end


    -- =========================================
    -- SWITCH VIEW
    -- =========================================

    SKIN:Bang(
        '!SetVariable',
        'CurrentView',
        'BadgeDetail'
    )

    SKIN:Bang(
        '!HideMeterGroup',
        'GoalBadgesView'
    )

    SKIN:Bang(
        '!HideMeterGroup',
        'SpecialBadgesView'
    )

    SKIN:Bang(
        '!ShowMeterGroup',
        'BadgeDetailView'
    )


    SKIN:Bang(
        '!SetOption',
        'HeaderLabel',
        'Text',
        'DATA // BADGE DETAILS'
    )

    SKIN:Bang(
        '!SetOption',
        'HeaderGlow',
        'Text',
        'DATA // BADGE DETAILS'
    )

    SKIN:Bang(
        '!SetOption',
        'SystemStatus',
        'Text',
        'SYS // INSPECTION'
    )

    SKIN:Bang(
        '!SetOption',
        'FooterLeft',
        'Text',
        'BADGE: INSPECT'
    )


    SKIN:Bang(
        '!UpdateMeter',
        '*'
    )

    SKIN:Bang(
        '!Redraw'
    )

end

function ShowTrackDetails(trackId)

    badgeDetailReturnView = 'GoalBadges'

    local stats =
        loadAchievementStats()

    local data =
        getTrackData(
            trackId,
            stats
        )

    if not data then
        return
    end

    SKIN:Bang(
        '!ShowMeter',
        'BadgeTrackRail'
    )

    SKIN:Bang(
        '!ShowMeter',
        'BadgeTrackFillGlow'
    )

    SKIN:Bang(
        '!ShowMeter',
        'BadgeTrackFill'
    )

    SKIN:Bang(
        '!SetOption',
        'BadgeDetailName',
        'Text',
        '> ' ..
        data.name ..
        ' TRACK'
    )


    SKIN:Bang(
        '!SetOption',
        'BadgeDetailStatus',
        'Text',
        'LEVEL // ' ..
        tostring(data.level)
    )


    SKIN:Bang(
        '!SetOption',
        'BadgeDetailStatus',
        'FontColor',
        '#AccentColor#'
    )


    SKIN:Bang(
        '!SetOption',
        'BadgeDetailType',
        'Text',
        'TYPE // PROGRESSION'
    )


    SKIN:Bang(
        '!SetOption',
        'BadgeDetailDescription',
        'Text',
        'CURRENT // ' ..
        tostring(data.count) ..
        ' CLEARED'
    )


    SKIN:Bang(
        '!SetOption',
        'BadgeDetailRequirement',
        'Text',
        'NEXT // ' ..
        tostring(
            data.nextThreshold
        )
    )


    local progress =
        data.count -
        data.currentThreshold

    local required =
        data.nextThreshold -
        data.currentThreshold

    local fillWidth = 0

    if required > 0 then

        fillWidth =
            math.floor(
                (progress / required) *
                260
            )

    end


    if fillWidth < 0 then
        fillWidth = 0
    elseif fillWidth > 260 then
        fillWidth = 260
    end

    SKIN:Bang(
        '!SetOption',
        'BadgeTrackFill',
        'Shape',
        'Rectangle 0,0,' ..
        tostring(fillWidth) ..
        ',5 | Fill Color #AccentColor# | StrokeWidth 0'
    )


    SKIN:Bang(
        '!SetOption',
        'BadgeTrackFillGlow',
        'Shape',
        'Rectangle 0,0,' ..
        tostring(fillWidth + 2) ..
        ',7 | Fill Color #GlowStrong# | StrokeWidth 0'
    )

    SKIN:Bang(
        '!SetOption',
        'BadgeDetailProgress',
        'Text',
        tostring(progress) ..
        ' / ' ..
        tostring(required) ..
        ' TO LV. ' ..
        tostring(data.level + 1)
    )


    SKIN:Bang(
        '!SetOption',
        'BadgeDetailDate',
        'Text',
        ''
    )


    SKIN:Bang(
        '!SetVariable',
        'CurrentView',
        'BadgeDetail'
    )

    SKIN:Bang(
        '!HideMeterGroup',
        'GoalBadgesView'
    )

    SKIN:Bang(
        '!HideMeterGroup',
        'SpecialBadgesView'
    )

    SKIN:Bang(
        '!ShowMeterGroup',
        'BadgeDetailView'
    )


    SKIN:Bang(
        '!SetOption',
        'HeaderLabel',
        'Text',
        'DATA // PROGRESSION'
    )

    SKIN:Bang(
        '!SetOption',
        'HeaderGlow',
        'Text',
        'DATA // PROGRESSION'
    )

    SKIN:Bang(
        '!SetOption',
        'SystemStatus',
        'Text',
        'SYS // LEVEL DATA'
    )


    SKIN:Bang(
        '!UpdateMeter',
        '*'
    )

    SKIN:Bang(
        '!Redraw'
    )

end

function BackToBadges()

    SKIN:Bang(
        '!HideMeterGroup',
        'BadgeDetailView'
    )

    if badgeDetailReturnView == 'SpecialBadges' then

        SKIN:Bang(
            '!SetVariable',
            'CurrentView',
            'SpecialBadges'
        )

        SKIN:Bang(
            '!HideMeterGroup',
            'GoalBadgesView'
        )

        SKIN:Bang(
            '!ShowMeterGroup',
            'SpecialBadgesView'
        )

        SKIN:Bang(
            '!SetOption',
            'HeaderLabel',
            'Text',
            'DATA // SPECIAL BADGES'
        )

        SKIN:Bang(
            '!SetOption',
            'HeaderGlow',
            'Text',
            'DATA // SPECIAL BADGES'
        )

        SKIN:Bang(
            '!SetOption',
            'SystemStatus',
            'Text',
            'SYS // ARCHIVE'
        )

        SKIN:Bang(
            '!SetOption',
            'FooterLeft',
            'Text',
            'SPECIAL: RECORD'
        )

        drawSpecialBadges()

    else

        SKIN:Bang(
            '!SetVariable',
            'CurrentView',
            'GoalBadges'
        )

        SKIN:Bang(
            '!HideMeterGroup',
            'SpecialBadgesView'
        )

        SKIN:Bang(
            '!ShowMeterGroup',
            'GoalBadgesView'
        )

        SKIN:Bang(
            '!SetOption',
            'HeaderLabel',
            'Text',
            'DATA // ACHIEVEMENTS'
        )

        SKIN:Bang(
            '!SetOption',
            'HeaderGlow',
            'Text',
            'DATA // ACHIEVEMENTS'
        )

        SKIN:Bang(
            '!SetOption',
            'SystemStatus',
            'Text',
            'SYS // RECORD'
        )

        SKIN:Bang(
            '!SetOption',
            'FooterLeft',
            'Text',
            'BADGES: ACTIVE'
        )

        drawBadges()

    end

end

-- ==================================================
-- RETURN TO GOALS
-- ==================================================

function BackToGoals()

    hideHistoryLines()

    SKIN:Bang('!SetVariable', 'CurrentView', 'Goals')

    SKIN:Bang('!HideMeterGroup', 'GoalHistoryView')
    SKIN:Bang('!HideMeterGroup', 'GoalStatsView')
    SKIN:Bang('!HideMeterGroup','SpecialBadgesView')
    SKIN:Bang('!HideMeterGroup','GoalBadgesView')
    SKIN:Bang('!HideMeterGroup','BadgeDetailView')

    SKIN:Bang('!ShowMeterGroup', 'SharedViewport')
    SKIN:Bang('!ShowMeterGroup', 'ViewSelector')
    SKIN:Bang('!ShowMeterGroup', 'GoalsView')

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
        '#DimColor#'
    )

    SKIN:Bang(
        '!SetOption',
        'ViewGoals',
        'FontColor',
        '#AccentColor#'
    )

    SKIN:Bang(
        '!SetOption',
        'ViewIndicator',
        'X',
        '106'
    )

    SKIN:Bang(
        '!SetOption',
        'HeaderLabel',
        'Text',
        'DATA // GOAL TRACKING'
    )

    SKIN:Bang(
        '!SetOption',
        'HeaderGlow',
        'Text',
        'DATA // GOAL TRACKING'
    )

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

    SKIN:Bang(
        '!SetOption',
        'FooterLeft',
        'Text',
        'TRACKER: ACTIVE'
    )

    SKIN:Bang('!UpdateMeasure', 'MeasureGoalTracker')
    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end


function Update()
    return ''
end

