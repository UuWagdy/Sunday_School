using System.Text.Json.Nodes;

namespace SundaySchool.SyncServer.Services;

public static class ScopedSettingsMerge
{
    public static string Merge(string key,string? previous,string incoming,HashSet<string> visible)
    {
        if(key=="monthly_fund_payments_json")
        {
            var old=JsonNode.Parse(string.IsNullOrEmpty(previous)?"{}":previous)!.AsObject();
            var next=JsonNode.Parse(incoming)!.AsObject();
            foreach(var id in next.Select(x=>x.Key)) if(!visible.Contains(id)) throw new UnauthorizedAccessException();
            foreach(var id in old.Select(x=>x.Key).Where(visible.Contains).ToList()) old.Remove(id);
            foreach(var (id,value) in next) old[id]=value?.DeepClone();
            return old.ToJsonString();
        }
        var groups=new Dictionary<string,JsonObject>();
        foreach(var item in JsonNode.Parse(string.IsNullOrEmpty(previous)?"[]":previous)!.AsArray())
        {
            var group=item!.AsObject().DeepClone().AsObject();
            var hidden=new JsonArray((group["members"]?.AsArray() ?? new()).Where(m=>!visible.Contains(m?["id"]?.ToString() ?? "")).Select(m=>m?.DeepClone()).ToArray());
            if(hidden.Count>0) { group["members"]=hidden; groups[group["name"]!.ToString()]=group; }
        }
        var names=new HashSet<string>();
        foreach(var item in JsonNode.Parse(incoming)!.AsArray())
        {
            var group=item!.AsObject().DeepClone().AsObject();
            var name=group["name"]!.ToString();
            if(!names.Add(name)) throw new UnauthorizedAccessException();
            var members=group["members"]?.AsArray() ?? new();
            if(members.Any(m=>!visible.Contains(m?["id"]?.ToString() ?? ""))) throw new UnauthorizedAccessException();
            if(groups.TryGetValue(name,out var protectedGroup))
                foreach(var m in members) protectedGroup["members"]!.AsArray().Add(m?.DeepClone());
            else groups[name]=group;
        }
        return new JsonArray(groups.Values.Select(g=>(JsonNode)g).ToArray()).ToJsonString();
    }
}
