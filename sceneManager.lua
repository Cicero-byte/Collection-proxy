-- scenemanager.lua
-- Um módulo reutilizável para gerenciar transições de cena (coleção) em Defold.

local M = {}

-- CONFIGURAÇÃO
M.proxies = {}               -- Tabela que mapeia IDs de cena para URLs de proxy.
M.current_scene_id = nil     -- O ID da cena atualmente carregada e ativa.

-- ESTADO INTERNO
local scenes_to_load = {}    -- Fila de cenas para carregar.
local is_transitioning = false -- Flag para evitar transições simultâneas.

-- Função interna para iniciar a transição real.
local function _start_transition()
	if is_transitioning or #scenes_to_load == 0 then
		return -- Já está em transição ou não há nada na fila.
	end

	is_transitioning = true
	local scene_id = table.remove(scenes_to_load, 1) -- Pega o primeiro da fila.
	local proxy_url = M.proxies[scene_id]

	if proxy_url then
		print("[SceneManager] Carregando cena '" .. tostring(scene_id) .. "' em " .. tostring(proxy_url))
		msg.post(proxy_url, "load")
	else
		print("[SceneManager] ERRO: Proxy para a cena '" .. tostring(scene_id) .. "' não encontrado.")
		is_transitioning = false
	end
end

--- Registra as cenas que o gerenciador pode controlar.
-- @param scenes_table Tabela no formato { [id_da_cena] = url_da_proxy }
function M.register(scenes_table)
	M.proxies = scenes_table
	print("[SceneManager] Cenas registradas.")
end

--- Inicia a transição para uma nova cena.
-- Esta é a principal função a ser chamada de fora.
-- @param scene_id O ID da cena para a qual transicionar (ex: hash("level1")).
function M.transition(scene_id)
	print("[SceneManager] Solicitação de transição para a cena: " .. tostring(scene_id))

	-- Evita transição redundante para a mesma cena
	if scene_id == M.current_scene_id then
		print("[SceneManager] Cena '" .. tostring(scene_id) .. "' já está ativa. Ignorando transição.")
		return
	end

	-- Verifica se a cena está registrada
	if not M.proxies[scene_id] then
		print("[SceneManager] ERRO: Cena '" .. tostring(scene_id) .. "' não registrada.")
		return
	end

	-- Evita múltiplas entradas iguais na fila
	for _, id in ipairs(scenes_to_load) do
		if id == scene_id then
			print("[SceneManager] Cena '" .. tostring(scene_id) .. "' já está na fila.")
			return
		end
	end

	table.insert(scenes_to_load, scene_id)
	_start_transition()
end

--- Função que deve ser chamada pelo on_message do script controlador.
-- Ela processa as mensagens do sistema de proxy.
function M.on_message(message_id, message, sender)
	-- Ouve pela mensagem que o Defold envia quando uma proxy termina de carregar.
	if message_id == hash("proxy_loaded") then
		local new_proxy_url = sender
		local new_scene_id = nil

		-- Descobre qual ID de cena corresponde à proxy que acabou de carregar.
		for id, url in pairs(M.proxies) do
			if tostring(url) == tostring(new_proxy_url) then
				new_scene_id = id
				break
			end
		end

		if not new_scene_id then
			print("[SceneManager] ERRO: Recebido 'proxy_loaded' de uma proxy desconhecida: " .. tostring(sender))
			is_transitioning = false
			return
		end

		-- 1. Se uma cena já estiver ativa, desabilita e descarrega para liberar memória.
		if M.current_scene_id and M.proxies[M.current_scene_id] then
			local old_proxy_url = M.proxies[M.current_scene_id]
			if tostring(old_proxy_url) ~= tostring(new_proxy_url) then
				print("[SceneManager] Descarregando cena antiga: " .. tostring(M.current_scene_id))
				msg.post(old_proxy_url, "disable")
				msg.post(old_proxy_url, "unload")
			end
		end

		-- 2. Ativa a nova cena que foi carregada.
		print("[SceneManager] Ativando nova cena: " .. tostring(new_scene_id))
		msg.post(new_proxy_url, "enable")

		-- 3. Atualiza o estado interno do gerenciador.
		M.current_scene_id = new_scene_id
		is_transitioning = false

		print("[SceneManager] Transição para '" .. tostring(new_scene_id) .. "' completa.")

		-- 4. Verifica se há outra transição na fila para iniciar.
		_start_transition()
	end
end

return M