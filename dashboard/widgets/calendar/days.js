.pragma library

// The 42 days on a month grid (6 weeks) for the month of `first` (its 1st), starting on `weekStart`
// (0 = Sunday … 6 = Saturday): { day, weekday (0 = Sunday), current (in that month), today }.
function days(first, now, weekStart) {
    var out = [];
    var lead = (first.getDay() - weekStart + 7) % 7;
    for (var i = 0; i < 42; i++) {
        var d = new Date(first.getFullYear(), first.getMonth(), 1 - lead + i);
        out.push({
            day: d.getDate(),
            weekday: d.getDay(),
            current: d.getMonth() === first.getMonth(),
            today: d.toDateString() === now.toDateString()
        });
    }
    return out;
}

// The 7 days of the week holding `day` (a Date), starting on `weekStart`: the same fields as days(),
// `current` = in `day`'s month
function week(day, now, weekStart) {
    var out = [];
    var lead = (day.getDay() - weekStart + 7) % 7;
    for (var i = 0; i < 7; i++) {
        var d = new Date(day.getFullYear(), day.getMonth(), day.getDate() - lead + i);
        out.push({
            day: d.getDate(),
            weekday: d.getDay(),
            current: d.getMonth() === day.getMonth(),
            today: d.toDateString() === now.toDateString(),
            time: d.getTime()
        });
    }
    return out;
}
