'use strict';

function datetimestring(locales, options, posixtime) {
    return new Intl.DateTimeFormat(locales, options).format(new Date(posixtime))
}
