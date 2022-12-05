--[[
    "A* turtle"
    Author: Bryon Olfert
    Date: 7/8/2019

    Edits: 7/11/2019 - Added increased scores for blocks that turn.
    Edits: 9/05/2019 - instant indexing with dictionary tree
    Edits: 10/16/2019 - added binary heap indexing
                      - reimplemented turning prevention

    Parameters: 
    start:{x,y,z,direction}
    endPoint:{x,y,z}
    blocks:{x{y{z{}}}}

    Returns: Array of point by point directions to get from start to endpoint.

    block structure: {gscore,hscore,fscore,camefrom}
]]


--simple distance formula for generating heuristic score
function distance(x1,y1,z1,x2,y2,z2)
    return math.abs((x2-x1))+math.abs((y2-y1))+math.abs((z1-z2))
end

-- function returns boolean for if given table index exists
function tableExists(table)
    return table ~= nil
end

--returns if table index exists but more powerful
function tableExistsAdvanced(table,x,y,z)
    if tableExists(table) == false then
        return false
    elseif tableExists(table[x]) == false then
        return false
    elseif tableExists(table[x][y]) == false then
        return false
    elseif tableExists(table[x][y][z]) == false then
        return false
    else
        return true
    end
end

--adds blocks to dictionary
function updateBlock(table,x,y,z)
    if tableExists(table[x]) == false then
        table[x] = {}
        table[x][y] = {}
        table[x][y][z] = {}
    elseif tableExists(table[x][y]) == false then
        table[x][y] = {}
        table[x][y][z] = {}
    elseif tableExists(table[x][y][z]) == false then
        table[x][y][z] = {}
    end
end

--heap: returns heap elements children
function getChildren(parent)
    local child = parent * 2
    return child,child + 1
end
  
--heap: returns heap elements parent
function getParent(child)
    return math.floor(child / 2)
end
  
--heap: raises element in heap to correct position
function swim(child,array)

    local c = child
    local p = getParent(child)

    if p == 0 then
        --nothing
    else

        --checks if child is less than parent
        while array[c][1] <= array[p][1] do

            --swaps child and parrent element
            array[c],array[p] = array[p],array[c]
            c = p
            p = getParent(c)

            --if p is 0 then the end of the heap is reached
            if p == 0 then
                break
            end

        end

    end
end
  
--heap: lowers element in heap to correct position
function sink(parent,array)

    local c1,c2 = getChildren(parent)
    local p = parent

    -- checks if parent element has both children
    if tableExists(array[c1]) == true and tableExists(array[c2]) == true then

        -- loops while parent is larger than either of it's children
        while array[p][1] > array[c1][1] or array[p][1] > array[c2][1] do

            --swaps position with it's smallest child
            if array[c1][1] < array[c2][1] then
                array[c1],array[p] = array[p],array[c1]
                p = c1
            else
                array[c2],array[p] = array[p],array[c2]
                p = c2
            end

            --get new children after swaping parent with child
            c1,c2 = getChildren(p)

            --tests if parent has no child
            if tableExists(array[c1]) == false then
                break
            --tests if parent has only 1 child
            elseif tableExists(array[c2]) == false then
                --tests if parents only child is smaller than it
                if array[p][1] > array[c1][1] then
                    array[c1],array[p] = array[p],array[c1]
                end
                --if element is where it should be, stop looping
                break
            end

        end

    --tests if parent has only 1 child
    elseif tableExists(array[c1]) == true then

        --tests if parent is larger than child
        if array[p][1] > array[c1][1] then
            --swaps child and parent
            array[c1],array[p] = array[p],array[c1]
        end

    end
end
  
--heap: removes element from heap
function pull(pos,array)
    array[pos],array[#array] = array[#array],array[pos]
    table.remove(array,#array)
    sink(1,array)
end
  
--heap: adds element to array
function add(data,array)
    table.insert(array,data)
    swim(#array,array)
end

--main function
function aStar(start,endPoint,blocks)
    
    local startPoint = {start[1],start[2],start[3]}

    -- The set of nodes already evaluated
    local closedSet = {}

    -- The set of currently discovered nodes that are not evaluated yet.
    -- Initially, only the start node is known.
    local openSetSize = 1
    local openSet = {}
    updateBlock(openSet,startPoint[1],startPoint[2],startPoint[3])
    openSet[startPoint[1]][startPoint[2]][startPoint[3]] = {0,0,0,0}

    -- sets first element in heap
    local heapTable = {{0,startPoint}}

    -- Sets ratio between speed and accuracy (0.00-1.00)
    local gWeight = 1.00

    --timout counter
    local time = os.time()
    local endTime = 15
 
    --MAIN START--

    local done = false
    local current = nil
    local count = 0

    --loops while there are still blocks to test and timeout hasn't been reached
    while (openSetSize > 0 and done == false) and ((os.time() - time) * 50 < endTime) do
            
        -- continue pathing

        --sleep prevents "too long without yelding" error
        if count % 300 == 0 then
            sleep(0.05)
        end

        --get lowest fscore in heapTable
        local cur = nil
        local x,y,z = nil,nil,nil

        --removes heap elements that have been removed from open set
        repeat
            cur = heapTable[1][2]
            x,y,z = cur[1],cur[2],cur[3]
            pull(1,heapTable)
        until tableExists(openSet[x][y][z])

        --Set placeholder for block selected from the top of the heap
        current = {x,y,z,openSet[x][y][z][4]}

        --tests if current is the endpoint
        if (current[1] == endPoint[1] and current[2] == endPoint[2] and current[3] == endPoint[3])  then
            
            --table to store the final path(order is backwords)
            local path = {}
            table.insert(path,endPoint)
            --adds blocks to path
            while (current[1] ~= startPoint[1] or current[2] ~= startPoint[2]) or current[3] ~= startPoint[3] do
                table.insert(path,{current[4][1],current[4][2],current[4][3]})
                current = {current[4][1],current[4][2],current[4][3],closedSet[current[4][1]][current[4][2]][current[4][3]][4]}
            end
                
            done = true

            --flips order of path elemements to return proper step by step order
            local i, j = 1, #path
            while i < j do
                path[i], path[j] = path[j], path[i]
                i = i + 1
                j = j - 1
            end

            return path

        end
        
        --adds current to closedset
        updateBlock(closedSet,current[1],current[2],current[3])
        closedSet[current[1]][current[2]][current[3]] = openSet[current[1]][current[2]][current[3]]

        --removes current from openset
        openSet[current[1]][current[2]][current[3]] = nil
        openSetSize = openSetSize - 1

        --table to store current blocks neighbors 
        local neighbors = {}

        --creating current blocks neighbors
        table.insert(neighbors,{current[1]+1,current[2],current[3]})
        table.insert(neighbors,{current[1],current[2]+1,current[3]})
        table.insert(neighbors,{current[1]-1,current[2],current[3]})
        table.insert(neighbors,{current[1],current[2]-1,current[3]})
        table.insert(neighbors,{current[1],current[2],current[3]+1})
        table.insert(neighbors,{current[1],current[2],current[3]-1})

        -- looping through neighbors to add them to open set
        for i = 1, #neighbors do
            local neighborInClosedSet = false
            local neighborInOpenSet = false
			-- checks if neighbor is in closed set already
			if tableExistsAdvanced(closedSet,neighbors[i][1],neighbors[i][2],neighbors[i][3]) == true then
					neighborInClosedSet = true
			end

			if neighborInClosedSet == false then
                
                --tests if neighbor is in open set
                if tableExistsAdvanced(openSet,neighbors[i][1],neighbors[i][2],neighbors[i][3]) == true then
					neighborInOpenSet = true
                end
                
            end
            
            if neighborInClosedSet == false then
                -- tempG stores the total distance traveled from start to current block
                local tempG = closedSet[current[1]][current[2]][current[3]][1] + gWeight

                --gets currents previous block
                local from1 = closedSet[current[1]][current[2]][current[3]][4]

                --tests if previous was the startpoint
                if not (from1 == 0) then
                    
                    --gets the previous block of currents previous block
                    local from2 = closedSet[from1[1]][from1[2]][from1[3]][4]
                    
                    --tests using from1 and from2 to test if reaching the neighnoring block requires a turn
                    if not (from2 == 0) and not (current[1] == 2 * from1[1] - from2[1] and current[2] == 2 * from1[2] - from2[2]) then
                        tempG  = tempG + gWeight
                    end
                end

                --newPath tests if a block already in open list has been discoved to be more useful in a different path
                local newPath = false

                --testing for more optimal use of an open set block
                if neighborInOpenSet == true then
                
                    if tempG < openSet[neighbors[i][1]][neighbors[i][2]][neighbors[i][3]][1] then
                        openSetSize = openSetSize - 1
                        newPath = true

                    end
                
                else
                    
                    -- neighboring block is neither in closed set or openset; neighbor is added to openset
                    newPath = true
                    
                end

                -- tests if neighbor is a known block
                if tableExistsAdvanced(blocks,neighbors[i][1],neighbors[i][2],neighbors[i][3]) == true then
                    newPath = false
                end

                --scores neighbor block
                if newPath == true then
                    updateBlock(openSet,neighbors[i][1],neighbors[i][2],neighbors[i][3])
                    openSet[neighbors[i][1]][neighbors[i][2]][neighbors[i][3]][1] = tempG
                    openSet[neighbors[i][1]][neighbors[i][2]][neighbors[i][3]][2] = distance(neighbors[i][1],neighbors[i][2],neighbors[i][3],endPoint[1],endPoint[2],endPoint[3])
                    openSet[neighbors[i][1]][neighbors[i][2]][neighbors[i][3]][3] = tempG + distance(neighbors[i][1],neighbors[i][2],neighbors[i][3],endPoint[1],endPoint[2],endPoint[3])
                    openSet[neighbors[i][1]][neighbors[i][2]][neighbors[i][3]][4] = {current[1],current[2],current[3]}
                    openSetSize = openSetSize + 1
                    
                    --adds neighbor to heap
                    add({openSet[neighbors[i][1]][neighbors[i][2]][neighbors[i][3]][3],{neighbors[i][1],neighbors[i][2],neighbors[i][3]}},heapTable)

                end
            end
        end

        count = count + 1
    end

    if done == false then
        return "failed"
    end

end
