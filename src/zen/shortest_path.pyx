#cython: embedsignature=True

import heapq 
from digraph cimport DiGraph
from graph cimport Graph
import numpy as np
cimport numpy as np
from zen.exceptions import ZenException
from zen.util.fiboheap cimport FiboHeap

__all__ = [
		'single_source_shortest_path',
		'single_source_shortest_path_',		
		'single_source_shortest_path_length',
		'single_source_shortest_path_length_',		
		'dijkstra',
		'dijkstra_',
		'pred2path',
		'pred2path_',
		'floyd_warshall',
		'floyd_warshall_',
		'all_pairs_dijkstra_path',
		'all_pairs_dijkstra_path_',
		'all_pairs_dijkstra_path_length',
		'all_pairs_dijkstra_path_length_'
		]

cpdef single_source_shortest_path(G,source,target=None):
	"""
	This function computes the single source shortest path in an unweighted network
	by trading space for speed.  The algorithm requires several blocks of memory whose
	size are on the order of the number of nodes in the network.  Thus for very large networks,
	dijkstra's algorithm may be faster.
	
	Return value is a dictionary, D, where D[x] is a tuple (d,p), d is the distance of node x
	from the source and p is the predecessor of node x on the path to the source. 
	
	If the target is specified, the return value is the distance from source to target and the path
	from source to target, returned as a list of nodes along the path.
	"""
	cdef int i, num_nodes
	cdef int src_idx, tgt_idx
	cdef np.ndarray[np.double_t, ndim=1] D # final distance
	cdef np.ndarray[np.int_t, ndim=1] P # predecessors
	
	num_nodes = len(G)
	src_idx = G.node_idx(source)
	tgt_idx = -1
	if target is not None:
		tgt_idx = G.node_idx(target)
	
	D,P = single_source_shortest_path_(G,src_idx,tgt_idx)
	
	if target is None:
		Dist = dict()
		for i in range(num_nodes):
			if P[i] >= 0:
				pred = G.node_object(P[i])
			else:
				pred = None
				
			Dist[G.node_object(i)] = (D[i],pred)
			
		return Dist
	else:
		d = D[tgt_idx]
		p = None
		if d != float('infinity'):
			p = []
			i = tgt_idx
			while i >= 0:
				p.insert(0,G.node_object(i))
				i = P[i]
			
		return d,p

cpdef single_source_shortest_path_(G,int source,int target=-1):
	"""
	This function computes the single source shortest path in an unweighted network
	by trading space for speed.  The algorithm requires several blocks of memory whose
	size are on the order of the number of nodes in the network.  Thus for very large networks,
	dijkstra's algorithm may be faster.
	
	Return values are a distance and predecessor numpy arrays.  If the target is specified, the algorithm
	halts when the target node is reached.  In this case, the distance and predecessor arrays will
	be partially completed.
	"""
	if type(G) == Graph:
		return single_source_shortest_path_u_(<Graph> G,source,target,True)
	else:
		return single_source_shortest_path_d_(<DiGraph> G,source,target,True)
		
cpdef single_source_shortest_path_length(G,int source,int target=-1):
	"""
	This function computes the single source shortest path in an unweighted network
	by trading space for speed.  The algorithm requires several blocks of memory whose
	size are on the order of the number of nodes in the network.  Thus for very large networks,
	dijkstra's algorithm may be faster.

	Return value is a distance numpy array.  If the target is specified, the algorithm
	halts when the target node is reached.  In this case, the distance array will
	be partially completed.
	"""
	if type(G) == Graph:
		return single_source_shortest_path_u_(<Graph> G,source,target,False)
	else:
		return single_source_shortest_path_d_(<DiGraph> G,source,target,False)	
		
cpdef single_source_shortest_path_length_(G,int source,int target=-1):
	"""
	This function computes the single source shortest path in an unweighted network
	by trading space for speed.  The algorithm requires several blocks of memory whose
	size are on the order of the number of nodes in the network.  Thus for very large networks,
	dijkstra's algorithm may be faster.

	Return value is a distance numpy arrays.  If the target is specified, the algorithm
	halts when the target node is reached.  In this case, the distance array will
	be partially completed.
	"""
	if type(G) == Graph:
		return single_source_shortest_path_u_(<Graph> G,source,target,False)
	else:
		return single_source_shortest_path_d_(<DiGraph> G,source,target,False)	
		
cpdef single_source_shortest_path_u_(Graph G,int source,int target,bool gen_predecessors):
	
	cdef np.ndarray[np.double_t, ndim=1] distance = np.zeros(G.num_nodes, np.double) # final distance
	distance.fill(float('infinity'))
	
	cdef np.ndarray[np.int_t, ndim=1] predecessor
	if gen_predecessors:
		predecessor = np.zeros(G.num_nodes, np.int) # predecessors
		predecessor.fill(-1)
	
	cdef np.ndarray[np.int_t, ndim=1] seen = np.zeros(G.num_nodes, np.int)
	cdef np.ndarray[np.int_t, ndim=1] curr_level = np.zeros(G.num_nodes, np.int)
	cdef np.ndarray[np.int_t, ndim=1] next_level = np.zeros(G.num_nodes, np.int)
	cdef int curr_level_size
	cdef int next_level_size
	cdef int curr_depth
	cdef int eidx, uidx, vidx
	
	next_level_size = 1
	next_level[0] = source
	distance[source] = 0
	if gen_predecessors:
		predecessor[source] = -1
	seen[source] = True
	curr_depth = 1
	
	while next_level_size > 0:
		curr_level,next_level = next_level,curr_level
		curr_level_size = next_level_size
		next_level_size = 0
		
		for i in range(curr_level_size):
			uidx = curr_level[i]

			for ec in range(G.node_info[uidx].degree):
				eidx = G.node_info[uidx].elist[ec]
				vidx = G.endpoint_(eidx,uidx)
				
				if seen[vidx] == True:
					continue
					
				seen[vidx] = True
				
				distance[vidx] = curr_depth
				if gen_predecessors:
					predecessor[vidx] = uidx
					
				next_level[next_level_size] = vidx
				next_level_size += 1
				
				if vidx == target:
					break
					
			if target >= 0 and seen[target] == True:
				break
			
		if target >= 0 and seen[target] == True:
			break
			
		curr_depth += 1
	
	if gen_predecessors:
		return distance, predecessor
	else:
		return distance
	
cpdef single_source_shortest_path_d_(DiGraph G,int source,int target,bool gen_predecessors):

	cdef np.ndarray[np.double_t, ndim=1] distance = np.zeros(G.num_nodes, np.double) # final distance
	distance.fill(float('infinity'))
	cdef np.ndarray[np.int_t, ndim=1] predecessor
	if gen_predecessors:
		predecessor = np.zeros(G.num_nodes, np.int) # predecessors
		predecessor.fill(-1)

	cdef np.ndarray[np.int_t, ndim=1] seen = np.zeros(G.num_nodes, np.int)
	cdef np.ndarray[np.int_t, ndim=1] curr_level = np.zeros(G.num_nodes, np.int)
	cdef np.ndarray[np.int_t, ndim=1] next_level = np.zeros(G.num_nodes, np.int)
	cdef int curr_level_size
	cdef int next_level_size
	cdef int curr_depth
	cdef int eidx, uidx, vidx

	next_level_size = 1
	next_level[0] = source
	distance[source] = 0
	if gen_predecessors:
		predecessor[source] = -1
	seen[source] = True
	curr_depth = 1

	while next_level_size > 0:
		curr_level,next_level = next_level,curr_level
		curr_level_size = next_level_size
		next_level_size = 0

		for i in range(curr_level_size):
			uidx = curr_level[i]

			for ec in range(G.node_info[uidx].outdegree):
				eidx = G.node_info[uidx].outelist[ec]
				vidx = G.edge_info[eidx].tgt

				if seen[vidx] == True:
					continue

				seen[vidx] = True

				distance[vidx] = curr_depth
				if gen_predecessors:
					predecessor[vidx] = uidx

				next_level[next_level_size] = vidx
				next_level_size += 1

				if vidx == target:
					break

			if target >= 0 and seen[target] == True:
				break

		if target >= 0 and seen[target] == True:
			break

		curr_depth += 1

	if gen_predecessors:
		return distance, predecessor
	else:
		return distance
		
cpdef dijkstra(G, start, end=None):
	""" 
	if end is not None: returns (distance, path) from start to end.
	if end is not reachable, (inf, None) is returned.

	if end is None, returns a dictionary where D[x] = (distance to x, predecessor to x)
	"""
	cdef int i, pred_idx, end_idx, n
	
	# compute the result
	if end in G:
		end_idx = G.node_idx(end)
	else:
		end_idx = -1
	
	start_idx = G.node_idx(start)

	distance, predecessor = dijkstra_(G, G.node_idx(start), end_idx)

	if end == None: # single source
		# store in a dictionary
		result = {}
	
		for i in xrange(distance.size):

			pred_idx = predecessor[i]

			if pred_idx < 0:
				pred = None 
			else:
				pred = G.node_object(pred_idx)
				assert pred != None, 'predecessor node with index %d does not exist' % pred_idx

			node = G.node_object(i)

			assert node != None, 'node with index %d does not exist' % i
		
			result[node] = (distance[i], pred)
	
		return result
	
	else:
		# return the distance value as well as the path as a list of node objects
		if start_idx == end_idx:
			return 0, []
			
		path = pred2path_(start_idx, end_idx, predecessor)
		if path is None:
			return float('infinity'), None
		else:
			return distance[end_idx], [G.node_object(x) for x in path]
		
	
cpdef dijkstra_(G, int start_idx, int end_idx=-1):
	"""
	Return a distance array D and predecessor array P where D[i] is the length of the shortest path 
	from node with index start_idx to the node with index i and P[i] is the precedecessor index for node with 
	index i

	If any indexes are -1, then there was no distance / no predecessor
	"""
	if type(G) == DiGraph:
		return dijkstra_d_(<DiGraph> G, start_idx, end_idx, True)
	elif type(G) == Graph:
		return dijkstra_u_(<Graph> G, start_idx, end_idx, True)
	else:
		raise ZenException, 'Graph of type %s not supported' % str(type(G))

cdef dijkstra_d_(DiGraph G, int start_idx, int end_idx, bool gen_predecessors):
	"""
	Dijkstra algorithm for directed graphs.
	
    Returns an array of distances and predecessors.
	"""
	
	cdef np.ndarray[np.double_t, ndim=1] distance = np.empty([G.num_nodes], dtype=np.double) # final distance
	cdef np.ndarray[np.int_t, ndim=1] predecessor
	if gen_predecessors:
		predecessor = np.empty([G.num_nodes], dtype=np.int) # predecessors
		
	cdef np.ndarray[object, ndim=1] fiboheap_nodes = np.empty([G.num_nodes], dtype=object) # holds all of our FiboHeap Nodes Pointers
	
	cdef int edge_idx, node_idx
	cdef int w,i
	cdef double vw_distance, dist
	cdef double infinity = float('infinity')
		
	Q = FiboHeap()
	#set of all nodes in Graph, since all nodes are not optimized they are in the Q.
	for i from 0<= i < G.num_nodes:
		distance[i] = infinity
		if gen_predecessors:
			predecessor[i] = -1
			
		if i != start_idx:
			fiboheap_nodes[i]=Q.insert(infinity, i) #float('infinity'), i)
			
	fiboheap_nodes[start_idx] = Q.insert(0, start_idx)
	distance[start_idx] = 0
	
	if gen_predecessors:
		predecessor[start_idx] = -1
	
	while Q.get_node_count() != 0:
		node_idx = Q.extract()
		dist = distance[node_idx]
		if dist == infinity:
			break #all remaining vertices are inaccessible from source
		
		for i in xrange(G.node_info[node_idx].outdegree):
			edge_idx = G.node_info[node_idx].outelist[i]
			w = G.edge_info[edge_idx].tgt
			vw_distance = dist + G.weight_(edge_idx)
			if distance[w] == infinity or (vw_distance < distance[w]): #Relax
				distance[w] = vw_distance
				if gen_predecessors:
					predecessor[w] = node_idx
				Q.decrease_key(fiboheap_nodes[w], vw_distance)
	
	# TODO: do we need to cleanup the fiboheap_nodes array?
		
	if gen_predecessors:
		return distance, predecessor
	else:
		return distance

def dijkstra_cmp(x,y):
	return cmp(x.cost,y.cost)
	
cdef dijkstra_u_(Graph G, int start_idx, int end_idx, bool gen_predecessors):
	"""
	Dijkstra algorithm for undirected graphs.
	
    Returns an array of distances and predecessors.
	"""
	cdef np.ndarray[np.double_t, ndim=1] distance = np.empty([G.num_nodes], dtype=np.double) # final distance
	cdef np.ndarray[np.int_t, ndim=1] predecessor
	if gen_predecessors:
		predecessor = np.empty([G.num_nodes], dtype=np.int) # predecessors
	cdef np.ndarray[object, ndim=1] fiboheap_nodes = np.empty([G.num_nodes], dtype=object) # holds all of our FiboHeap Nodes Pointers
	
		
	cdef int edge_idx, node_idx
	cdef int w,i
	cdef double vw_distance, dist
	cdef double infinity = float('infinity')
	
	Q = FiboHeap()
	#set of all nodes in Graph, since all nodes are not optimized they are in the Q.
	for i from 0<= i < G.num_nodes:
		distance[i] = infinity
		if gen_predecessors:
			predecessor[i] = -1
		if i != start_idx:
			fiboheap_nodes[i]=Q.insert(infinity, i)
			
	fiboheap_nodes[start_idx] = Q.insert(0, start_idx)
	distance[start_idx] = 0
	if gen_predecessors:
		predecessor[start_idx] = -1
	
	while Q.get_node_count() != 0:
		node_idx = Q.extract()
		dist = distance[node_idx]
		if dist == infinity:
			break #all remaining vertices are inaccessible from source
		
		
		for i in xrange(G.node_info[node_idx].degree):
			edge_idx = G.node_info[node_idx].elist[i]
			w = G.endpoint_(edge_idx, node_idx)
			vw_distance =  dist + G.weight_(edge_idx)
			if distance[w] == infinity or (vw_distance < distance[w]): #Relax
				distance[w] = vw_distance
				if gen_predecessors:
					predecessor[w] = node_idx
				Q.decrease_key(<object>fiboheap_nodes[w], vw_distance)
	
	if gen_predecessors:
		return distance, predecessor
	else:
		return distance

cpdef pred2path(start_obj, end_obj, R):
	"""
	Construct a shortest path from start_obj to end_obj using the output of a shortest path
	function, R. The path is a list of encountered node objects from start_obj to end_obj.
  	"""
	if type(R[start_obj]) == dict:
		R = R[start_obj]
		return _pred2path_sssp_output(start_obj,end_obj,R)
	else:
		return _pred2path_sssp_output(start_obj,end_obj,R)
			
cdef _pred2path_sssp_output(start_obj, end_obj, R):

	if R[end_obj][1] == None:
		return None # that node is not reachable

	if start_obj == end_obj:
		return [] # silly case

	path = [end_obj]
	n = R[end_obj][1]
	while n != start_obj:
		path.append(n)
		n = R[n][1]

	path.append(start_obj)
	path.reverse()

	return path

cpdef pred2path_(int start_idx, int end_idx, np.ndarray predecessor):
	"""
	Construct a shortest path from start_idx to end_idx using the predecessor output of a shortest
	path algorithm.	The path returned is a list of encountered node indexes from start_idx to end_idx.

	start_idx and end_idx must be node indexes for valid nodes in the graph.
  	"""
	# NOTE(druths): It would generally be preferable for this function to return a path as a numpy array
	# since this would be more consistent with the index-oriented return policies.  However, the reason 
	# a numpy array is not returned by this function is because the length of the path (and thus of the 
	# numpy array) cannot be deduced from the predecessor object without traversing it.  This would incur
	# add additional time costs.  
	#    It's worth noting that it *might* be faster to traverse it once, get
	# the length of the path, and then build a numpy array rather than build a list (since this requires)
	# multiple calls into the Python VM.  This is a topic that should be investigated further.
	
	if predecessor.ndim == 1:
		return _pred2path_sssp_output_(start_idx, end_idx, <np.ndarray> predecessor)
	elif predecessor.ndim == 2:
		return _pred2path_apsp_output_(start_idx, end_idx, <np.ndarray> predecessor)
	else:
		raise ZenException, 'distance and predecessor numpy objects must have 1 or 2 dimensions'

cdef _pred2path_sssp_output_(int start_idx, int end_idx, np.ndarray[np.int_t, ndim=1] predecessor):
	"""
	This reconstructs a numpy path from the distance, predecessor output of a single source shortest
	path algorithm.  The path is a list of the node indicies.
	"""
	if predecessor[end_idx] == -1:
		return None

	if start_idx == end_idx:
		return []

	path = [end_idx]
	n = predecessor[end_idx]
	while n != start_idx:
		path.append(n)
		n = predecessor[n]

	path.append(start_idx)
	path.reverse()

	return path
	
cdef _pred2path_apsp_output_(int start_idx, int end_idx, np.ndarray[np.int_t, ndim=2] predecessor):
	"""
	This reconstructs a numpy path from the distance, predecessor output of a all-pairs source shortest
	path algorithm.
	"""
	if predecessor[start_idx,end_idx] == -1:
		return None

	if start_idx == end_idx:
		return [] # silly case

	path = [end_idx]
	n = predecessor[start_idx,end_idx]
	while n != start_idx:
		path.append(n)
		n = predecessor[start_idx,n]

	path.append(start_idx)
	path.reverse()

	return path
	
cpdef flag_unreachable(np.ndarray A):
	cdef int i

	for i in xrange(A.size):
		if A[i] == -1:
			A[i] = -2 # -2 means unreachable 

cpdef floyd_warshall(G):
	"""
	Return a dictionary, D, of node object tuples (x,y), where D[(x,y)] = the length of the
	shortest path connecting node x to node y.
	"""
	cdef int i,j
	
	# compute the result
	P = floyd_warshall_(G)
	
	# store it in a dictionary
	result = {}
	nodes_lookup = G.nodes_(obj=True)
	
	for i in range(len(nodes_lookup)):
		for j in range(i,len(nodes_lookup)):
			result[(nodes_lookup[i,1],nodes_lookup[j,1])] = P[nodes_lookup[i,0],nodes_lookup[j,0]]
			result[(nodes_lookup[j,1],nodes_lookup[i,1])] = P[nodes_lookup[j,0],nodes_lookup[i,0]]
			
	return result
	
cpdef floyd_warshall_(G):
	"""
	Return a distance matrix P where P[i,j] is the length of the shortest path 
	from node with index i to the node with index j.
	"""
	if type(G) == DiGraph:
		return floyd_warshall_d_(<DiGraph> G)
	elif type(G) == Graph:
		return floyd_warshall_u_(<Graph> G)
	else:
		raise Exception, 'Graphs of type %s not supported' % str(type(G))

cpdef floyd_warshall_d_(DiGraph G):
	"""
	Floyd-Warshall algorithm for directed graphs.
	
	Return a distance matrix P where P[i,j] is the length of the shortest path 
	from node with index i to the node with index j.
	"""
	cdef int i,j,k
	cdef int ni,nj,nk
	cdef np.ndarray[np.double_t, ndim=2] P
	cdef np.ndarray[np.int_t, ndim=1] nodes
	cdef int num_nodes
	cdef double tmp
	#cdef np.ndarray[np.int_t, ndim=1] nodes
	
	nodes = G.nodes_()
	num_nodes = len(nodes)
	max_num_nodes = nodes.max() + 1
	
	P = np.ones( (max_num_nodes, max_num_nodes), dtype=np.double)
	P = P * float('infinity')
	
	# initialize the path matrix
	for i in range(num_nodes):
		ni = nodes[i]
		P[ni,ni] = 0
		for j in range(G.node_info[i].outdegree):
			nj = G.edge_info[G.node_info[i].outelist[j]].tgt
			P[ni,nj] = 1
	
	# compute shortest paths...
	for i in range(num_nodes):
		ni = nodes[i]
		for j in range(num_nodes):
			nj = nodes[j]
			for k in range(num_nodes):
				nk = nodes[k]
				tmp = P[ni,nk] + P[nk,nj]
				if tmp < P[ni,nj]:
					P[ni,nj] = tmp
			
	return P

cpdef floyd_warshall_u_(Graph G):
	"""
	Floyd-Warshall algorithm for directed graphs.

	Return a distance matrix P where P[i,j] is the length of the shortest path 
	from node with index i to the node with index j.
	"""
	cdef int i,j,k
	cdef int ni,nj,nk
	cdef np.ndarray[np.double_t, ndim=2] P
	cdef np.ndarray[np.int_t, ndim=1] nodes
	cdef int num_nodes
	cdef double tmp
	#cdef np.ndarray[np.int_t, ndim=1] nodes

	nodes = G.nodes_()
	num_nodes = len(nodes)
	max_num_nodes = nodes.max() + 1

	P = np.ones( (max_num_nodes, max_num_nodes), dtype=np.double)
	P = P * float('infinity')

	# initialize the path matrix
	for i in range(num_nodes):
		ni = nodes[i]
		P[ni,ni] = 0
		for j in range(G.node_info[i].degree):
			nj = G.edge_info[G.node_info[i].elist[j]].u
			if nj == ni:
				nj = G.edge_info[G.node_info[i].elist[j]].v
			P[ni,nj] = 1

	# compute shortest paths...
	for i in range(num_nodes):
		ni = nodes[i]
		for j in range(num_nodes):
			nj = nodes[j]
			for k in range(num_nodes):
				nk = nodes[k]
				tmp = P[ni,nk] + P[nk,nj]
				if tmp < P[ni,nj]:
					P[ni,nj] = tmp

	return P			

cpdef all_pairs_dijkstra_path(G):
	"""
	Compute the shortest paths between all pairs of nodes in G.  The result is a dictionary of dictionaries, R, where R[x][y] is a
	tuple (d,p) indicating the length of the shortest path from x to y, d, and the predecessor on that path.
	"""
	R = dict()
	for n in G.nodes_iter():
		R[n] = dijkstra(G,n)
		
	return R
	
cpdef all_pairs_dijkstra_path_(G):
	"""
	Compute the shortest paths between all pairs of nodes in G.  The result is two NxN matricies, D and P, containing pairwise distances
	and predecessors respectively.  D[x,y] is the length of the path leading from x to y and P[x,y] is the immediate predecessor to y
	on the shortest path from x.  All node identifiers are node indicies.
	"""
	cdef int next_node_idx = G.next_node_idx
	cdef int nidx
	
	cdef np.ndarray[np.double_t, ndim=1] distances = np.empty([next_node_idx], dtype=np.double) # final distance
	cdef np.ndarray[np.int_t, ndim=1] predecessors = np.empty([next_node_idx], dtype=np.int) # predecessors

	for nidx in range(next_node_idx):
		D,P = dijkstra_(G,nidx)
		distances[nidx,:] = D
		predecessors[nidx,:] = P

	return distances, predecessors

cpdef all_pairs_dijkstra_path_length(G):
	pass

cpdef all_pairs_dijkstra_path_length_(G):
	"""
	Compute the shortest paths between all pairs of nodes in G.  The result is one NxN matricies, D, containing pairwise distances.  
	D[x,y] is the length of the path leading from x to y. All node identifiers are node indicies.
	"""
	cdef int next_node_idx = G.next_node_idx
	cdef int nidx
	
	cdef np.ndarray[np.double_t, ndim=1] distances = np.empty([next_node_idx], dtype=np.double) # final distance

	for nidx in range(next_node_idx):
		D,P = dijkstra_(G,nidx)
		distances[nidx,:] = D

	return distances