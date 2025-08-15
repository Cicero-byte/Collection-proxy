
---

### 3. Implemente o `controller.script`

```lua
-- /main/controller.script
local scenemanager = require "main.modules.scenemanager"

function init(self)
    -- Todas as cenas devem ser adicionadas aqui
    local scenes = {
        [hash("menu")]    = msg.url("#menu_proxy"),
        [hash("level1")]  = msg.url("#level1_proxy"),
        [hash("credits")] = msg.url("#credits_proxy"),
    }

    -- Aqui todas as cenas serão registradas
    scenemanager.register(scenes)

    -- Geralmente queremos carregar uma cena inicial aqui como ex o menu
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

-- Para trocar de cenas poste essa mensagem no seu codigo, essa linha pode ser chamada em qualquer scrip para
-- Fazer a troca de cenas
msg.post(msg.url("main:/controller#controller"), "transition_to", { scene_id = hash("level1") })


