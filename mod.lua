-- set some globals for later
MOD_NAME = "sample_workbench"
SPR_REF = {}
SLOT_SPR = -1
RECIPE_SPR = -1
ARROW_SPR = -1
TAB_1_SPR = -1
TAB_1_SELECTED_SPR = -1
TAB_2_SPR = -1
TAB_2_SELECTED_SPR = -1
CAN_CRAFT_SPR = -1
CANT_CRAFT_SPR = -1


-- register the mod
function register()
  return {
    name = MOD_NAME,
    hooks = {}
  }
end


-- initialise the mod
function init() 

  -- create some custom sprites that we'll use for the menu
  SLOT_SPR = api_define_sprite("workbench_item_slot", "sprites/workbench-item-slot.png", 2)
  RECIPE_SPR = api_define_sprite("workbench_recipe_slot", "sprites/workbench-recipe-slot.png", 1)
  ARROW_SPR = api_define_sprite("workbench_arrow", "sprites/workbench-arrow.png", 1)
  CAN_CRAFT_SPR = api_define_sprite("workbench_craft", "sprites/workbench-craft.png", 2)
  CANT_CRAFT_SPR = api_define_sprite("workbench_craft_error", "sprites/workbench-craft-error.png", 2)
  TAB_1_SPR = api_define_sprite("workbench_tab_1", "sprites/workbench-tab-1.png", 2)
  TAB_1_SELECTED_SPR = api_define_sprite("workbench_tab_1_s", "sprites/workbench-tab-1-selected.png", 2)
  TAB_2_SPR = api_define_sprite("workbench_tab_2", "sprites/workbench-tab-2.png", 2)
  TAB_2_SELECTED_SPR = api_define_sprite("workbench_tab_2_s", "sprites/workbench-tab-2-selected.png", 2)

  -- actually define the menu object
  api_define_menu_object(
    {
      id = "workbench",
      name = "Sample Workbench",
      category = 'Crafting',
      tooltip = 'Hello craft things with me yes',
      layout = {},
      info = {
        {'1. Crafting Area', 'WHITE'}
      },
      tools = {"hammer1"},
      buttons = {'Help', 'Move', 'Close'}
    }, 
    '/sprites/sample-workbench.png',
    '/sprites/sample-workbench-menu.png',
    {
      define = 'workbench_define_script',
      draw = 'workbench_draw_script',
      tick = 'workbench_tick_script'
    },
    nil
  )

  -- store a reference for each sprite we'll need later for crafting
  -- NB: if you wanted to craft with custom items you'll need to have 
  -- defined them BEFORE you use api_get_sprite
  SPR_REF = {
    log = api_get_sprite('log'),
    planks1 = api_get_sprite('planks1'),
    acorn1 = api_get_sprite('acorn1')
  }

  -- give ourselves one of the workbenches
  api_give_item(MOD_NAME .. '_workbench', 1, nil)

  return "Success"
end


-- define the workbench menu
function workbench_define_script(menu_id) 

  -- setup some variables
  api_dp(menu_id, "tab", "tab1")
  api_dp(menu_id, "selected_item", nil)
  api_dp(menu_id, "invalid", false)
  api_dp(menu_id, "ingredient1", "acorn1")
  api_dp(menu_id, "ingredient1_amount", 2)
  api_dp(menu_id, "ingredient2", nil)
  api_dp(menu_id, "ingredient3", nil)

  -- add our tabs
  api_define_button(menu_id, "tab1", 6, 16, "tab1", "workbench_tab_click", "sprites/workbench-tab-1-selected.png")
  api_define_button(menu_id, "tab2", 27, 16, "tab2", "workbench_tab_click", "sprites/workbench-tab-2.png")

  -- add crafting button
  api_define_button(menu_id, "craft_button", 50, 50, "Craft", "workbench_craft_click", "sprites/workbench-craft.png")

  -- add a single recipe slot
  -- if you had more slots you'd make more (duh)
  -- as you'll see we just change the text of this button when we change tabs
  api_define_button(menu_id, "recipe1", 7, 29, "log", "workbench_recipe_click", "sprites/workbench-slot.png")

end


-- workbench menu drawing
function workbench_draw_script(menu_id)

  -- get camera
  cam = api_get_cam()

  -- draw tabs
  api_draw_button(api_gp(menu_id, "tab1"), false)
  api_draw_button(api_gp(menu_id, "tab2"), false)

  -- draw recipe slot + item
  recipe1 = api_gp(menu_id, "recipe1")
  recipe1_oid = api_gp(recipe1, 'text')
  api_draw_button(recipe1, false)
  -- if this recipe is the same as whats "selected", draw a highlight before the item
  if api_gp(menu_id, "selected_item") == recipe1_oid then 
    api_draw_sprite(RECIPE_SPR, 0, api_gp(recipe1, 'x') - cam["x"], api_gp(recipe1, 'y') - cam["y"]) 
  end
  api_draw_sprite(SPR_REF[recipe1_oid], 0, api_gp(recipe1, 'x') - cam["x"], api_gp(recipe1, 'y') + 1 - cam["y"])

  -- draw selected recipe if any
  if api_gp(menu_id, 'selected_item') ~= nil then

    -- draw ingredients
    -- obvs you'd always expect 1
    -- but if you had 2/3 then you wanna render them conditionally
    -- then when you select a recipe you can just set the ones you dont need as nil
    ingredient1 = api_gp(menu_id, "ingredient1")
    if ingredient1 ~= nil then
      -- slot background + actual ingredient item
      api_draw_sprite(SLOT_SPR, 0, api_gp(menu_id, 'draw_x') + 55, api_gp(menu_id, 'draw_y') + 20) 
      api_draw_sprite(SPR_REF[ingredient1], 0, api_gp(menu_id, 'draw_x') + 57, api_gp(menu_id, 'draw_y') + 22)
      -- arrow
      api_draw_sprite(ARROW_SPR, 0, api_gp(menu_id, 'draw_x') + 81, api_gp(menu_id, 'draw_y') + 27)
      -- amount for the ingredients needed, checking invalid for showing red text
      text_col = "FONT_WHITE"
      if api_gp(menu_id, "invalid") == true then text_col = "FONT_RED" end
      api_draw_number(api_gp(menu_id, 'draw_x') + 57 + 19, api_gp(menu_id, 'draw_y') + 22 + 20, 1, text_col)
    end
    
    -- draw recipe output
    api_draw_sprite(SLOT_SPR, 1, api_gp(menu_id, 'draw_x') + 98, api_gp(menu_id, 'draw_y') + 20)
    api_draw_sprite(SPR_REF[recipe1_oid], 0, api_gp(menu_id, 'draw_x') + 100, api_gp(menu_id, 'draw_y') + 22)
    api_draw_number(api_gp(menu_id, 'draw_x') + 100 + 19, api_gp(menu_id, 'draw_y') + 22 + 20, 2, "FONT_WHITE")

    -- draw the crafting button
    api_draw_button(api_gp(menu_id, "craft_button"), true)


  end

end


-- every 0.1s if the workbench is open with a selected recipe check if we have enough items
function workbench_tick_script(menu_id)

  -- open + selected item
  if api_gp(menu_id, "open") == true then
    if api_gp(menu_id, "selected_item") ~= nil then
      -- get the amount for the ingredient needed
      can_craft = api_use_total(api_gp(menu_id, "ingredient1")) >= 1
      -- update invalid prop and swap out button sprite between green + red
      if can_craft then
        api_sp(menu_id, "invalid", false)
        api_sp(api_gp(menu_id, "craft_button"), "sprite_index", CAN_CRAFT_SPR)
      else
        api_sp(menu_id, "invalid", true)
        api_sp(api_gp(menu_id, "craft_button"), "sprite_index", CANT_CRAFT_SPR)
      end
      
    end
  end

end


-- change tab when clicked on
function workbench_tab_click(menu_id, button_id)

  -- check what tab we clicked on, using the "text" as an id
  tab = api_gp(button_id, 'text')

  -- tab 1, set recipes
  if tab == 'tab1' then 
    -- set the tab sprites for a "selected" sprite
    api_sp(api_gp(menu_id, "tab1"), "sprite_index", TAB_1_SELECTED_SPR)
    api_sp(api_gp(menu_id, "tab2"), "sprite_index", TAB_2_SPR)
    -- obviously this is hardcoded but it'd be easy enough to dynamically set all your recipe slots
    -- and have as many recipe slots as you need
    api_sp(api_gp(menu_id, "recipe1"), 'text', "log")
  end

  -- tab 2, set recipes
  if tab == 'tab2' then 
    -- set the tab sprites for a "selected" sprite
    api_sp(api_gp(menu_id, "tab2"), "sprite_index", TAB_2_SELECTED_SPR)
    api_sp(api_gp(menu_id, "tab1"), "sprite_index", TAB_1_SPR)
    -- obviously this is hardcoded but it'd be easy enough to dynamically set all your recipe slots
    -- and have as many recipe slots as you need
    api_sp(api_gp(menu_id, "recipe1"), 'text', "planks1")
  end

  -- update the "selected" item and current tab
  api_sp(menu_id, 'selected_item', nil)
  api_sp(menu_id, "tab", tab)

end


-- set ingredients on recipe click
function workbench_recipe_click(menu_id, button_id)

  -- set the selected item as the "recipe" we clicked on
  recipe1 = api_gp(menu_id, "recipe1")
  recipe1_oid = api_gp(recipe1, 'text')
  api_sp(menu_id, 'selected_item', recipe1_oid)

  -- again, hardcoded cos im lazy but you could do this dynamically
  -- we're just setting our "ingredients" based on the selected recipe
  if recipe1_oid == "log" then
    api_sp(menu_id, "ingredient1", "acorn1")
    api_sp(menu_id, "ingredient1_amount", 1)
  end
  if recipe1_oid == "planks1" then
    api_sp(menu_id, "ingredient1", "log")
    api_sp(menu_id, "ingredient1_amount", 1)
  end

end


-- try and craft the recipe on button press
function workbench_craft_click(menu_id, button_id)

  -- not gunna hurt to recheck here again in-case someone drops the items on a frame
  -- between our tick handler function
  can_craft = api_use_total(api_gp(menu_id, "ingredient1")) >= 1
  if can_craft then
    -- use up the amount of ingredients and give the amount of recipe item
    api_use_item(api_gp(menu_id, "ingredient1"), 1)
    api_give_item(api_gp(menu_id, "selected_item"), 2)
  end

end