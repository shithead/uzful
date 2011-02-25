--------------------------------------------------------------------------------
-- @author dodo
-- @copyright 2011 https://github.com/dodo
-- @release v3.4-503-g4972a28
--------------------------------------------------------------------------------

local wibox = require("wibox")
local util = require("awful.util")
local menu = require("uzful.menu.popup")
local naughty = require("naughty")
local vicious = require("vicious")
local beautiful = require("beautiful")
local setmetatable = setmetatable
local ipairs = ipairs
local pairs = pairs
local table = table
local widgets = {}


module("uzful.notifications")


data = {}

function patch()
    local notification = naughty.notify
    naughty.notify = function (args)
        update(notification(args), args)
    end
end


function update(notification, args)
    args = args or {}
    local preset = args.preset or naughty.config.default_preset or {}
    local icon = args.icon or preset.icon
    local text = args.text or preset.text or ""
    local screen = args.screen or preset.screen or 1
    local theme = beautiful.get()
    local color = {
        fg_normal = args.fg or preset.fg or theme.fg_normal or '#ffffff',
        bg_normal = args.bg or preset.bg or theme.bg_normal or '#535d6c',
        border_color = args.border_color or preset.border_color or
                       theme.bg_focus or '#535d6c',
    }
    local new_data = {
        notification = notification,
        screen = screen,
        theme = color,
        text = text,
        icon = icon }
    table.insert(data, new_data)

    local updates = {}
    for wid, conf in pairs(widgets) do
        if conf.screen == screen then
            updates[wid] = wid
        end
    end
    for _,wid in pairs(updates) do
        wid:add(new_data)
    end
end


function add(wid, args)
    local conf = widgets[wid]
    if conf == nil or not conf.visible then return end
    wid.number = wid.number + 1

    local setMarkup = function ()
        wid.text:set_markup(vicious.helpers.format(conf.format, { wid.number }))
    end
    setMarkup()
    local item
    local mouse_fun = function ()
        wid.number = wid.number - 1
        setMarkup()
        args.notification.die()
        wid.menu:delete(item)
        wid:show()
        local i = util.table.hasitem(args)
        if i then  table.remove(data, i)  end
    end

    local more = {"more …", {} }
    local new_item = {
            theme = args.theme or {}, args.text or "", mouse_fun, args.icon }
    local just_add = function (menu)
        item = menu:add(new_item)
    end
    local add_to_table
    add_to_table = function (t)
        if #t >= wid.max then
            if #t == wid.max then
                table.insert(t, more)
            end
            add_to_table(t[wid.max + 1][2])
        else
            table.insert(t, new_item)
        end
    end
    local add_to_menu
    add_to_menu = function (menu)
        if #menu.items >= wid.max then
            if #menu.items == wid.max then
                menu:add(more)
            end
            local cmd = menu.items[wid.max + 1].cmd
            if #cmd >= wid.max then
                local child = menu.child[wid.max + 1]
                if child then
                    add_to_menu(child)
                else
                    add_to_table(cmd)
                end
            else
                item = menu:add_sub(wid.max + 1, new_item)
            end
        else
            just_add(menu)
        end
    end

    if not wid.max or wid.max == 0 then
        just_add(wid.menu)
    else
        if #wid.menu.items >= wid.max then
            add_to_menu(wid.menu)
        else
            just_add(wid.menu)
        end
    end
    if conf.menu_visible then
        wid:show(conf.menu_args)
    end
end


function show(wid, args)
    local conf = widgets[wid]
    if conf == nil then return end
    if conf.visible then
        conf.menu_visible = true
        conf.menu_args = args
        wid.menu:show(args)
    end
end


function hide(wid)
    local conf = widgets[wid]
    if conf == nil then return end
    if conf.visible then
        conf.menu_visible = false
        wid.menu:hide()
    end
end


function toggle_menu(wid, args)
    local conf = widgets[wid]
    if conf == nil then return end
    if conf.visible then
        conf.menu_visible = not conf.menu_visible
        wid.menu:toggle(args)
    end
end


function enable(wid)
    local conf = widgets[wid]
    if conf == nil or conf.visible then return end
    conf.visible = true
    wid.text:set_markup(vicious.helpers.format(conf.format, { wid.number }))
    naughty.suspend()
end


function disable(wid)
    local conf = widgets[wid]
    if conf == nil or not conf.visible then return end
    local new = {}
    for _, v in pairs(data) do
        if v.screen ~= conf.screen then
            table.insert(new, v)
        end
    end
    wid:hide()
    for i = 1, #wid.menu.items do
        wid.menu:delete(conf.menu.len + 1)
    end
    data = new
    wid.number = 0
    conf.visible = false
    wid.text:set_markup(conf.disabled)
    naughty.resume()
end


function toggle(wid)
    local conf = widgets[wid]
    if conf == nil then return end
    if conf.visible then
        wid:disable()
    else
        wid:enable()
    end
end


function new(screen, args)
    screen = screen or 1
    args = args or {}

    local conf = {
        disabled = vicious.helpers.format(args.disabled or "$1", { "⤫" }),
        format = args.text or "$1",
        menu = args.menu or {},
        menu_visible = false,
        visible = args.visible ~= nil and args.visible,
        screen = screen }

    local ret = {
        max = args.max or 0,
        menu = menu(conf.menu),
        text = wibox.widget.textbox(),
        toggle_menu = toggle_menu,
        disable = disable,
        enable = enable,
        toggle = toggle,
        number = 0,
        show = show,
        hide = hide,
        add = add }
    widgets[ret] = conf
    conf.menu.len = #ret.menu.items

    for _, v in pairs(data) do
        if v.screen == screen then
            ret:add(v)
        end
    end

    conf.visible = not conf.visible
    ret:toggle()

    return ret
end


setmetatable(_M, { __call = function (_, ...) return new(...) end })