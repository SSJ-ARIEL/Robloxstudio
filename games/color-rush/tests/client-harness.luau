-- Local client smoke simulation; this does not execute Roblox's renderer or physics.
local objects, mounts, sent = {}, {}, {}
local function signal()
 local s={listeners={}}
 function s:Connect(f) table.insert(self.listeners,f);return{Disconnect=function()end}end
 function s:fire(...) for _,f in ipairs(self.listeners)do f(...)end end
 return s
end
local Node={}
Node.__index=function(self,k)
 if k=='Parent'then return rawget(self,'_parent')end
 if Node[k]then return Node[k]end
 if k=='Activated'then local s=signal();rawset(self,k,s);return s end
 return rawget(self,k)
end
Node.__newindex=function(self,k,v)
 if k=='Parent'then
  local prior=rawget(self,'_parent');if prior then for i,c in ipairs(prior.children)do if c==self then table.remove(prior.children,i);break end end end
  rawset(self,'_parent',v);if v then table.insert(v.children,self)end
 else rawset(self,k,v)end
end
function Node:IsA(t)return t==self.ClassName or t=='GuiObject'and table.find({'Frame','TextLabel','TextButton','ViewportFrame','ScrollingFrame'},self.ClassName)~=nil end
function Node:GetChildren()return table.clone(self.children)end
function Node:Destroy()for _,c in ipairs(self:GetChildren())do c:Destroy()end;self.Parent=nil;self.destroyed=true end
function Node:FindFirstChild(name,recursive)for _,c in ipairs(self.children)do if c.Name==name then return c end;if recursive then local match=c:FindFirstChild(name,true);if match then return match end end end end
function Node:WaitForChild(name)return assert(self:FindFirstChild(name),name)end
function Node:GetPropertyChangedSignal()return signal()end
local function node(kind,name,parent)local o=setmetatable({ClassName=kind,Name=name or kind,children={},ZIndex=1,Active=kind=='TextButton'},Node);o.Parent=parent;table.insert(objects,o);return o end
local Instance={new=function(kind)return node(kind)end}
local function vector(x,y)return{X=x,Y=y}end
local Vector2={new=vector,zero=vector(0,0)}
local UDim={new=function(a,b)return{Scale=a,Offset=b}end}
local UDim2={}
function UDim2.new(xs,xo,ys,yo)return{X={Scale=xs or 0,Offset=xo or 0},Y={Scale=ys or 0,Offset=yo or 0}}end
function UDim2.fromOffset(x,y)return UDim2.new(0,x,0,y)end
function UDim2.fromScale(x,y)return UDim2.new(x,0,y,0)end
local Color3={fromRGB=function(r,g,b)return{r=r,g=g,b=b,_type='Color3'}end,new=function(r,g,b)return{r=r,g=g,b=b,_type='Color3'}end}
local function typeof(x)return type(x)=='table'and x._type or type(x)end
local Enum=setmetatable({},{__index=function(t,k)local d=setmetatable({},{__index=function(a,b)rawset(a,b,k..'.'..b);return a[b]end});rawset(t,k,d);return d end})
local delayed, mockClock = {}, 0
local task={spawn=function(f)f()end,delay=function(seconds,callback)table.insert(delayed,{Due=mockClock+seconds,Callback=callback})end}
local function advanceTime(seconds)
 mockClock+=seconds
 for i=#delayed,1,-1 do if delayed[i].Due<=mockClock then local callback=table.remove(delayed,i).Callback;callback()end end
end
local Random={new=function()return{NextInteger=function(_,low)return low end}end}
local workspace=node('Workspace');workspace.CurrentCamera=node('Camera');workspace.CurrentCamera.ViewportSize=vector(900,700)
local world=node('Folder','ColorRushWorld',workspace)
for i=1,5 do node('Part','Board'..i,world)end
node('Part','ReferenceBoard',world)
local player=node('Player','Ariel');node('PlayerGui','PlayerGui',player)
local shared=node('Folder','ColorRush');local storage=node('ReplicatedStorage');shared.Parent=storage
for _,n in ipairs({'Config','Characters','Portrait','Rules'})do node('ModuleScript',n,shared)end
local remotes=node('Folder','Remotes',shared)
local state=node('RemoteEvent','State',remotes);state.OnClientEvent=signal()
local action=node('RemoteEvent','Action',remotes)
function action:FireServer(kind,value)table.insert(sent,{kind,value})end
local input={TouchEnabled=false,InputBegan=signal()}
local services={Players={LocalPlayer=player},ReplicatedStorage=storage,UserInputService=input,MarketplaceService={GetProductInfoAsync=function(_,id,kind)return{PriceInRobux=7,IsForSale=true}end}}
local game={GetService=function(_,key)return assert(services[key],key)end}
-- @CLIENT_MODULES@
local Portrait={mount=function(v,id,rgb,hidden)table.insert(mounts,{Id=id,RGB=rgb,Hidden=hidden});node('Camera','PortraitCamera',v);return node('Model','PortraitWorld',v)end}
local modules={Config=Config,Characters=Characters,Portrait=Portrait,Rules=Rules}
local function require(object)return assert(modules[object.Name],object.Name)end

local function clientMain()
-- @CLIENT_SOURCE@
end
clientMain()

local checks=0
local function check(value,message)checks+=1;assert(value,message)end
local function buttonWith(text)
 for _,o in ipairs(objects)do if not o.destroyed and o.ClassName=='TextButton'and o.Text==text then return o end end
 error('Button not found: '..text)
end
-- Zero-ID fixture uses actual offer metadata so entering real IDs later does not break the disabled-sale check.
local defaultCatalog={}
for _,product in ipairs(Config.Commerce.Products)do
 table.insert(defaultCatalog,{Key=product.Key,Kind='Product',Id=0,Available=false,Name=product.Name,Description=product.Description,SuggestedPrice=product.SuggestedPrice})
end
local vip=Config.Commerce.VIP
 table.insert(defaultCatalog,{Key=vip.Key,Kind='Pass',Id=0,Available=false,Name=vip.Name,Description=vip.Description,SuggestedPrice=vip.SuggestedPrice})
local configuredCatalog={}
for i,offer in ipairs(defaultCatalog)do configuredCatalog[i]=table.clone(offer)end
configuredCatalog[1].Id,configuredCatalog[1].Available,configuredCatalog[1].SuggestedPrice=101,true,999
local base={Phase='LOBBY',Message='Espera',Seconds=10,MatchId=1,Round=0,RunnerCount=2,Profile={Coins=60,Wins=2,Level=3,OwnedTrails={['1']=true},SelectedTrail=1,ReviveCredits=1,VIP=false,AutoRevive=false},Catalog=configuredCatalog}
local function snapshot(changes)local p=table.clone(base);for k,v in pairs(changes or{})do p[k]=v end;state.OnClientEvent:fire(p)end
check(sent[1][1]=='Sync','requests initial snapshot')
snapshot({Catalog=defaultCatalog})
buttonWith('ENTRENAR').Activated:fire()
buttonWith('ROBUX').Activated:fire()
check(#defaultCatalog==6,'actual catalog has five products and one pass')
local disabled=0
for _,o in ipairs(objects)do if not o.destroyed and o.ClassName=='TextButton'and o.Text=='NO DISPONIBLE'and not o.Active then disabled+=1 end end
check(disabled==6,'all six zero IDs disable sales by default')
local keys={}
for _,offer in ipairs(defaultCatalog)do keys[offer.Key]=true end
check(keys.revive1 and keys.revive3 and keys.coins200 and keys.coins800 and keys.coins2000 and keys.vip,'actual catalog keys match client contract')
snapshot()
check(buttonWith('COMPRAR  ·  R$ 7').Active==true,'uses current native price, not suggested price')
check(buttonWith('NO DISPONIBLE').Active==false,'zero ID disables purchase')
buttonWith('COMPRAR  ·  R$ 7').Activated:fire()
check(sent[#sent][1]=='ShopBuy'and sent[#sent][2].Key=='revive1','purchase sends key, never grants credit')
buttonWith('ESTELAS').Activated:fire()
buttonWith('MENTA  ·  60 monedas').Activated:fire()
check(sent[#sent][1]=='Trail'and sent[#sent][2]==2,'trail action uses numeric index')
buttonWith('AYUDA').Activated:fire()
buttonWith('REENTRADA AUTOMÁTICA: DESACTIVADA\nUsa solo créditos que ya tienes. Nunca compra automáticamente.').Activated:fire()
check(sent[#sent][1]=='AutoRevive'and sent[#sent][2]==true,'automatic reentry requires explicit preference')
buttonWith('X').Activated:fire()
snapshot({Phase='PREVIEW',CharacterId=1,Round=1,Seconds=2,Colors={{255,0,0},{0,255,0},{0,0,255},{255,255,0},{255,0,255}}})
check(world:FindFirstChild('Board1'):FindFirstChild('ColorRushPortrait')==nil,'preview does not reveal alternatives')
check(world:FindFirstChild('ReferenceBoard'):FindFirstChild('ColorRushPortrait')~=nil,'reference image mounted')
snapshot({Phase='RUN',CharacterId=1,Round=1,Seconds=12,Colors={{255,0,0},{0,255,0},{0,0,255},{255,255,0},{255,0,255}}})
check(world:FindFirstChild('Board5'):FindFirstChild('ColorRushPortrait')~=nil,'all five alternatives mounted')
local answerBoard=world:FindFirstChild('Board5'):FindFirstChild('ColorRushPortrait')
check(answerBoard.Size.X.Offset==0 and answerBoard.Size.X.Scale==10.5 and answerBoard.Size.Y.Scale==12.4,'answer portraits use world-size bounds narrower than lane spacing')
local referenceBoard=world:FindFirstChild('ReferenceBoard'):FindFirstChild('ColorRushPortrait')
check(referenceBoard.Size.X.Scale==23 and referenceBoard.Size.Y.Scale==17,'reference portrait uses separate world-size bounds')
check(mounts[#mounts].Hidden==true,'reference target masked during run')
local mounted=#mounts
snapshot({Phase='RUN',CharacterId=1,Round=1,Seconds=11,Colors={{255,0,0},{0,255,0},{0,0,255},{255,255,0},{255,0,255}}})
check(#mounts==mounted,'timer updates reuse all portrait models')
snapshot({Phase='REVEAL',CharacterId=1,Round=1,CorrectChoice=1,CanRevive=true,Seconds=5,Colors={{255,0,0},{0,255,0},{0,0,255},{255,255,0},{255,0,255}}})
check(mounts[#mounts].Hidden==false,'reveal restores original reference')
buttonWith('USAR 1 CRÉDITO').Activated:fire()
check(sent[#sent][1]=='UseRevive','existing credit consumption is explicit')
buttonWith('TIENDA').Activated:fire()
buttonWith('ÁLBUM').Activated:fire()
check(#mounts>=10,'free catalog gallery mounts ten portraits at once')
buttonWith('>').Activated:fire()
check(mounts[#mounts].Id==20,'album pagination reaches next characters')
check(#Characters.get(250).Name>0,'250th character accessible')
local function containsText(fragment)
 for _,o in ipairs(objects)do if not o.destroyed and type(o.Text)=='string'and string.find(o.Text,fragment,1,true)then return true end end
 return false
end
check(containsText('Una reentrada por jugador y partida, incluida la final.'),'one-credit cap is clearly disclosed')
check(containsText('Si compras un crédito y la partida ya terminó, lo conservas para otra.'),'late purchase remains a banked credit')
check(containsText('Nunca compra automáticamente.'),'automatic reentry is not an automatic purchase')
check(containsText('Cruzarla confirma tu elección'),'help matches authoritative first gate commitment')
buttonWith('X').Activated:fire()
local noCredits=table.clone(base.Profile);noCredits.ReviveCredits=0
snapshot({Phase='RUN',MatchId=2,CanRevive=true,Profile=noCredits})
local calls=#sent
buttonWith('VER CRÉDITO DE REENTRADA').Activated:fire()
check(#sent==calls,'no-credit reentry opens shop without initiating a purchase')
buttonWith('X').Activated:fire()
snapshot({Phase='REVEAL',MatchId=2,CanRevive=true,QueuedRevive=true})
check(buttonWith('USAR 1 CRÉDITO').Parent.Visible==false,'queued reentry hides further consumption')
snapshot({Phase='RESULTS',MatchId=2,CanRevive=false,WinnerName='Ariel'})
check(buttonWith('USAR 1 CRÉDITO').Parent.Visible==false,'announced result offers no revival')
-- Free practice never moves the player or requests currency, purchases, XP, or credits.
local function named(name)
 for _,o in ipairs(objects)do if not o.destroyed and o.Name==name then return o end end
 error('Object not found: '..name)
end
snapshot({Phase='LOBBY',MatchId=3,Alive=false,Eliminated=false})
buttonWith('ENTRENAR').Activated:fire()
local practiceStart=named('PracticeStart')
local actionCount=#sent
practiceStart.Activated:fire()
check(practiceStart.Text=='MEMORIZANDO...'and not practiceStart.Active,'practice starts with a disabled two-second preview')
for i=1,5 do named('PracticeChoice'..i).Activated:fire()end
check(#sent==actionCount,'clicks during preview cannot request actions')
advanceTime(1.9)
check(not named('PracticeChoice1').Active,'practice choices remain locked before two seconds')
advanceTime(0.1)
check(named('PracticeChoice1').Active and named('PracticeChoice5').Active,'practice unlocks all five choices after two seconds')
check(mounts[#mounts-5].Hidden==true,'practice masks the original before alternatives appear')
local matches,correctIndex=0,nil
for i=1,5 do
 local entry=mounts[#mounts-5+i]
 local target=Characters.get(entry.Id).TargetRGB
 if table.concat(entry.RGB,',')==table.concat(target,',')then matches+=1;correctIndex=i end
end
check(matches==1,'practice has exactly one correct original color among five portraits')
named('PracticeChoice'..correctIndex).Activated:fire()
check(practiceStart.Text=='OTRA IMAGEN'and practiceStart.Active,'correct practice answer enables another voluntary sample')
check(not named('PracticeChoice1').Active,'practice answer locks further choices')
check(#sent==actionCount,'practice answers grant no remote rewards and initiate no purchases')
practiceStart.Activated:fire()
local beforeCancel=#mounts
buttonWith('X').Activated:fire()
advanceTime(2)
check(#mounts==beforeCancel,'closing practice cancels pending portrait updates')
buttonWith('ENTRENAR').Activated:fire()
named('PracticeStart').Activated:fire()
beforeCancel=#mounts
buttonWith('ESTELAS').Activated:fire()
advanceTime(2)
check(#mounts==beforeCancel,'leaving the practice tab cancels its pending preview')
buttonWith('ENTRENAR').Activated:fire()
practiceStart=named('PracticeStart')
practiceStart.Activated:fire()
snapshot({Phase='PREVIEW',MatchId=4,Round=1,CharacterId=2,Alive=true,Colors={{255,0,0},{0,255,0},{0,0,255},{255,255,0},{255,0,255}}})
beforeCancel=#mounts
advanceTime(2)
check(#mounts==beforeCancel,'real-match preview cancels practice timers')
check(practiceStart.Parent.Parent.Parent.Parent.Visible==false,'real-match preview closes the training menu')
check(#sent==actionCount,'practice never calls server currency or purchase actions')
print('Color Rush UI smoke checks: '..checks..' passed (simulated engine).')

