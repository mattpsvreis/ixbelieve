net.Receive("RecieveDupe", function(len)
    local mode = net.ReadUInt(3)
    if (mode == 1) then
        local name = net.ReadString()
        local data = sql.Query("SELECT * FROM stored_dupes WHERE Name = '"..name.."';")
        net.Start("RecieveDupe")
        net.WriteString(data and data[1].Data or "")
        net.WriteUInt(file.Time(net.ReadString(), net.ReadString()), 32)
        net.WriteUInt(file.Time(net.ReadString(), net.ReadString()), 32)
        net.WriteUInt(file.Time(net.ReadString(), net.ReadString()), 32)
        net.WriteUInt(file.Time(net.ReadString(), net.ReadString()), 32)
        net.WriteUInt(file.Time(net.ReadString(), net.ReadString()), 32)
        net.SendToServer()
    elseif (mode == 2) then
        local name = net.ReadString()
        local data = sql.Query("SELECT * FROM stored_dupes WHERE Name = '"..name.."';")
        if (data) then
            local string = net.ReadString()
            sql.Query("UPDATE stored_dupes SET Data = '"..string.."' WHERE Name '"..name.."';")
        else
            local string = net.ReadString()
            sql.Query("INSERT INTO stored_dupes (Name, Data) VALUES ('"..name.."', '"..string.."');")
        end
    end
end)

if (!sql.TableExists("stored_dupes")) then
    sql.Query("CREATE TABLE stored_dupes ( Name TEXT, Data TEXT )")
end