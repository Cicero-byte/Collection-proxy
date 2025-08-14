
---

### 3. Implemente o `controller.script`

```lua
-- /main/controller.script
local scenemanager = require "main.modules.scenemanager"

function init(self)
    local scenes = {
        [hash("menu")]    = msg.url("menu_proxy"),
        [hash("level1")]  = msg.url("level1_proxy"),
        [hash("credits")] = msg.url("credits_proxy"),
    }

    scenemanager.register(scenes)
    msg.post(".", "transition_to", { scene_id = hash("menu") })
end

function on_message(self, message_id, message, sender)
    scenemanager.on_message(message_id, message, sender)

    if message_id == hash("transition_to") then
        scenemanager.transition(message.scene_id)
    end
end

----------------------------------------------------------------
Inicie Transições Entre Cenas
msg.post("/controller", "transition_to", { scene_id = hash("level1") })


