-- Persistence is independent from the world and from Roblox service discovery.
-- A caller must inject a Store acquired safely, or Enabled=false for practice.
-- Player_ keys, numeric receipt values and the legacy Data envelope are retained.
local Profiles = {}

local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}; for key, child in pairs(value) do result[key] = copy(child) end; return result
end

local function validReceipts(receipts)
	if receipts == nil then return true end
	if type(receipts) ~= "table" then return false end
	for id, amount in pairs(receipts) do
		if type(id) ~= "string" or #id == 0 or #id > 200 or type(amount) ~= "number"
			or amount ~= amount or amount <= 0 or amount == math.huge or amount % 1 ~= 0 then return false end
	end
	return true
end

function Profiles.new(deps)
	assert(type(deps) == "table" and type(deps.Economy) == "table" and type(deps.Ledger) == "table", "Profiles dependencies required")
	local Economy, Ledger, config = deps.Economy, deps.Ledger, deps.Config or {}
	local store, tasks = deps.Store, deps.Tasks or task
	local now, online = deps.Now or os.time, deps.IsOnline or function() return true end
	local clock = deps.Clock or os.clock
	local notify, onSaved = deps.Notify or function() end, deps.OnSaved or function() end
	local warnMessage = deps.Warn or warn
	local session = deps.SessionId or "session-only"
	local enabled = deps.Enabled ~= false and store ~= nil
	local maxCoins, maxReceipts = config.MaxCoins or 100000000, config.MaxReceipts or 10000
	local records, loading, controller = {}, {}, {}
	local closing, sequence = false, 0
	local function token()
		sequence += 1
		return deps.Token and deps.Token() or (session .. ":" .. tostring(now()) .. ":" .. sequence)
	end
	local function clean(raw) return Economy.clean(raw, now(), config) end
	local function envelope(data, release, commit)
		return { Data = data, Session = if release then nil else session,
			LeaseUntil = if release then nil else now() + 240, Commit = commit }
	end
	local function message(player, text) pcall(notify, player, text) end
	local function durable(player, data) pcall(onSaved, player, copy(data)) end
	local function acquire(record)
		while record.Saving do tasks.wait(0.1) end
		return record.Writable == true
	end

	function controller.get(player) return records[player] end

	function controller.load(player)
		if records[player] then return records[player] end
		if closing or loading[player] then return nil end
		loading[player] = true
		local data, writable = clean(nil), false
		if enabled then
			for attempt = 1, 3 do
				local commit = token()
				local ok, saved = pcall(function()
					return store:UpdateAsync("Player_" .. player.UserId, function(old)
						if type(old) == "table" and old.Session and old.Session ~= session and (tonumber(old.LeaseUntil) or 0) > now() then return nil end
						local raw = type(old) == "table" and (old.Data or old) or nil
						-- Never silently remove a receipt with damaged metadata.
						if type(raw) == "table" and not validReceipts(raw.Receipts) then return nil end
						return envelope(clean(raw), false, commit)
					end)
				end)
				if ok and type(saved) == "table" and saved.Session == session and saved.Commit == commit then
					data, writable = clean(saved.Data), true
					break
				end
				if attempt < 3 and online(player) and not closing then tasks.wait(attempt * 2) else break end
			end
		end
		local record = { Data = data, Ready = true, Writable = writable, Saving = false, Leaving = false,
			Revision = 0, SavedRevision = 0, VIP = false, VIPKnown = false, LastSaveFailed = false }
		records[player], loading[player] = record, nil
		if not online(player) or closing then
			record.Leaving = true
			controller.save(player, true)
			records[player] = nil
			return nil
		end
		if enabled and not writable then
			message(player, "No pudimos cargar tu guardado. Puedes jugar gratis; las compras y el guardado están pausados en esta sesión.")
		end
		return record
	end

	function controller.markDirty(player)
		local record = records[player]
		if record then record.Revision += 1 end
	end

	function controller.save(player, release)
		local record = records[player]
		if not record or not record.Writable or not acquire(record) or records[player] ~= record then return false end
		record.Saving = true
		local base, revision, commit = clean(record.Data), record.Revision, token()
		local lostLock = false
		local ok, saved = pcall(function()
			return store:UpdateAsync("Player_" .. player.UserId, function(old)
				lostLock = false
				if type(old) ~= "table" or old.Session ~= session then lostLock = true; return nil end
				if type(old.Data) ~= "table" or not validReceipts(old.Data.Receipts) then return nil end
				local merged = Ledger.merge(base, old.Data, maxCoins)
				return merged and envelope(merged, release, commit) or nil
			end)
		end)
		local reconciled = nil
		if ok and type(saved) == "table" and saved.Commit == commit
			and (release and saved.Session == nil or not release and saved.Session == session) then
			reconciled = Ledger.reconcile(record.Data, saved.Data, maxCoins)
		end
		if reconciled ~= nil then
			if reconciled > 0 then record.Revision += 1 end
			record.PendingPaid, record.UncertainReceipt = nil, nil
			record.LastSaveFailed, record.SavedRevision = false, revision
			if release then record.Writable = false end
		else
			record.LastSaveFailed = true
			if lostLock then record.Writable = false end
			warnMessage("Color Chaos: guardado no confirmado para " .. player.UserId)
			if not record.Leaving then message(player, "Tu guardado está pendiente. Estamos reintentando; las compras están pausadas.") end
		end
		record.Saving = false
		if reconciled ~= nil then durable(player, saved.Data) end
		return reconciled ~= nil
	end

	function controller.grantReceipt(player, receipt, product)
		local record = records[player]
		if not record or not record.Writable or record.Leaving then return false end
		if not acquire(record) or records[player] ~= record or record.Leaving then return false end
		if type(receipt) ~= "table" or type(receipt.PurchaseId) ~= "string" or #receipt.PurchaseId == 0 or #receipt.PurchaseId > 200 then return false end
		if type(product) ~= "table" or type(product.Coins) ~= "number" or product.Coins ~= product.Coins
			or product.Coins <= 0 or product.Coins > maxCoins or product.Coins % 1 ~= 0 then return false end
		if record.UncertainReceipt and record.UncertainReceipt ~= receipt.PurchaseId then return false end
		if record.LastSaveFailed and not record.UncertainReceipt then return false end
		record.Saving, record.PendingPaid = true, product.Coins
		local base, revision, commit = clean(record.Data), record.Revision, token()
		local lostLock = false
		local ok, saved = pcall(function()
			return store:UpdateAsync("Player_" .. player.UserId, function(old)
				lostLock = false
				if type(old) ~= "table" or old.Session ~= session then lostLock = true; return nil end
				if type(old.Data) ~= "table" or not validReceipts(old.Data.Receipts) then return nil end
				local receipts = old.Data.Receipts or {}
				if receipts[receipt.PurchaseId] == nil then
					local count = 0; for _ in pairs(receipts) do count += 1 end
					if count >= maxReceipts then return nil end
				end
				local merged = Ledger.grant(base, old.Data, receipt.PurchaseId, product.Coins, maxCoins)
				return merged and envelope(merged, false, commit) or nil
			end)
		end)
		local recovered = nil
		if ok and type(saved) == "table" and saved.Commit == commit and saved.Session == session
			and type(saved.Data) == "table" and type(saved.Data.Receipts) == "table" and saved.Data.Receipts[receipt.PurchaseId] ~= nil then
			recovered = Ledger.reconcile(record.Data, saved.Data, maxCoins)
		end
		if recovered ~= nil then
			if recovered > 0 then record.Revision += 1 end
			record.LastSaveFailed, record.PendingPaid, record.UncertainReceipt = false, nil, nil
			record.SavedRevision = revision
		else
			record.LastSaveFailed, record.UncertainReceipt = true, receipt.PurchaseId
			if lostLock then record.Writable = false end
		end
		record.Saving = false
		if recovered == nil then
			if tasks.delay then tasks.delay(2, function()
				if records[player] == record and record.Writable and not record.Leaving then controller.save(player, false) end
			end) end
			return false
		end
		durable(player, saved.Data)
		return true, recovered > 0 and ("Compra entregada: +" .. recovered .. " monedas.") or ""
	end

	-- User-triggered purchases/claims use a clone, so failures cannot partly spend
	-- funds. Gameplay rewards may mutate record.Data while persistence yields;
	-- callers then markDirty. Reconciliation only touches Coins and Receipts.
	function controller.mutate(player, callback)
		local record = records[player]
		if not record or record.Leaving or record.Saving then return false, "Espera un momento mientras guardamos." end
		local candidate = clean(record.Data)
		local ok, accepted, text, reward = pcall(callback, candidate)
		if not ok then warnMessage("Color Chaos: cambio de perfil rechazado."); return false, "No se pudo aplicar el cambio." end
		if accepted == false then return false, text end
		record.Data, record.Revision = candidate, record.Revision + 1
		return true, text, reward
	end

	function controller.public(player)
		local record = records[player]
		if not record then return nil end
		local view = Economy.view(record.Data, now())
		view.VIP, view.Persistence = record.VIP == true, record.Writable and (record.LastSaveFailed and "PENDING" or "ACTIVE") or "SESSION"
		return view
	end

	function controller.remove(player)
		local record = records[player]
		if not record then return end
		record.Leaving = true
		controller.save(player, true)
		records[player] = nil
	end

	function controller.close()
		closing = true
		local players, pending = {}, 0
		for player, record in pairs(records) do
			record.Leaving = true
			table.insert(players, player)
		end
		local deadline = clock() + 25
		local launch = tasks.spawn or function(callback) callback() end
		for _, player in ipairs(players) do
			pending += 1
			launch(function()
				local ok = pcall(controller.remove, player)
				if not ok then warnMessage("Color Chaos: no se pudo terminar el guardado al cerrar para " .. player.UserId) end
				pending -= 1
			end)
		end
		-- Roblox allows a short shutdown window: start every player's save before
		-- waiting, including profiles whose load is still acquiring a lease.
		while (pending > 0 or next(loading) ~= nil) and clock() < deadline do tasks.wait(0.1) end
		local finished = pending == 0 and next(loading) == nil
		if not finished then warnMessage("Color Chaos: algunos guardados siguen pendientes al cerrar el servidor.") end
		return finished
	end

	return controller
end

return Profiles
