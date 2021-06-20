import Foundation

var 周南: String {
    return ["采", "有", "掇", "捋", "袺", "襭"].map {
        "采采芣苢，薄言\($0)之。"
    }.joined(separator: "\n")
}

print(周南)

//采采芣苢，薄言采之。
//采采芣苢，薄言有之。
//采采芣苢，薄言掇之。
//采采芣苢，薄言捋之。
//采采芣苢，薄言袺之。
//采采芣苢，薄言襭之。

var 周南新: String {
    return ListFormatter.localizedString(byJoining: ["采", "有", "掇", "捋", "袺", "襭"].map {
        "采采芣苢，薄言\($0)之。"
    })
}
