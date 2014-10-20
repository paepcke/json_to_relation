db = db.getSiblingDB('modulestore')
// cursor = db.modulestore.find({}, {'_id' : 1, 'metadata.display_name' : 1}).toArray();
// while(cursor.hasNext()){
//     printjson(cursor.next());
// }

// The following .toArray() on cursor loads all of
// modulestore into memory. If you don't have enough
// RAM, need to change below to something that creates
// a legal array: use [<firstResult>,<secondResult>,...]
// Can try with commented sketch above. 
classDefs = db.modulestore.find({}, {'_id' : 1, 'metadata.display_name' : 1}).toArray();
printjson(classDefs);

