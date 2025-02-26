public import CASimEngine
public import Voxels

// Original implementation by William Van Der Scheer
// Master's Thesis, Utrecht University, 2022
// https://studenttheses.uu.nl/handle/20.500.12932/42762
// PDF available at https://studenttheses.uu.nl/bitstream/handle/20.500.12932/42762/Thesis_Final.pdf

// License CC0, as referenced
// https://git.science.uu.nl/w.g.vanderscheer/infomov-retro-voxel-fluids.git `WrldTmpl8-main/LICENSE`

// General execution flow for each iteration:
//    cape->Tick(deltaTime);
//    cape->ConvertToVoxels();

// MARK: CONSTANTS

let PRESSURE_ITERATIONS = 8
let MIN_VOXELMASS = 0.001
let VELOCITY_DAMPENING: Float = 0.1
let AL: Float = 0.5 // advection limiter
let INVAL: Float = 1.0 / AL // inverted advection limiter

let EVAPORATION: Float = 0.001 // The amount of mass to remove per cell per second (helps clean up low mass cells that are not visible.)
let MINRENDERMASS: Float = 0.001 // Don't render voxels below this much mass
let GRAVITYENABLED = 1
let CELLSIZE = 0.25 // In meters, essentially multiplier for gravity
// 0.333 is maximum 100% save speed, use up to 1.0 for less clamping
// and faster flowing water (less viscous), but requires that an appropriate
// time step is selected by the user, or simulation may blow up if local
// velocity becomes too high and negative mass is created
let MAXV = 1.0 // 0.33f

// namespace Tmpl8
// {
//
//    // CAPE - Cellular Automata Physics Engine
//    #define USECONCURRENCY 1
//    #define PRESSURE_ITERATIONS 8
//    #define DEBUG_MODE 1
//    #define CAPE_BRICKDIM 4
//    #define CAPE_GRIDWIDTH (MAPWIDTH / CAPE_BRICKDIM + 2)
//    #define CAPE_GRIDHEIGHT (MAPHEIGHT / CAPE_BRICKDIM + 2)
//    #define CAPE_GRIDDEPTH (MAPDEPTH / CAPE_BRICKDIM + 2)
//    #define CAPE_GRIDSIZE (CAPE_GRIDWIDTH * CAPE_GRIDHEIGHT * CAPE_GRIDDEPTH)
//    #define CAPE_BRICKSIZE (CAPE_BRICKDIM * CAPE_BRICKDIM * CAPE_BRICKDIM)
//    #define BIX(x, y, z) ((x)+(y) * (CAPE_GRIDWIDTH) + (z) * (CAPE_GRIDHEIGHT) * (CAPE_GRIDDEPTH))
//    #define MIN_BRICKMASS 0.001f
//    #define VELOCITY_DAMPENING 0.1f
//    #define AL 0.5f //Advection limiter, prevents oscillations
//    #define INVAL (1.0f/AL)
//
//
//    #define EVAPORATION 0.001f //amount of mass to remove per cell per second (helps clean up low mass cells that are not visible.)
//    #define MINRENDERMASS 0.001f //Dont render voxels below this much mass
//    #define GRAVITYENABLED 1
//    #define CELLSIZE 0.25f //In meters, essentially multiplier for gravity
//
//    //0.333 is maximum 100% save speed, use up to 1.0f for less clamping and faster flowing water (less viscous), but requires that an appropriate
//    //timestep is selected by the user, or simulation may blow up if local velocity becomes too high and negative mass is created
//    #define MAXV 1.0f //0.33f
//
//    class CAPE
//    {
//    public:
//        CAPE() {};
//        ~CAPE();
//
//        World* world;
//
//        //Run CA physics for this frame
//        void Tick(float deltaTime);
//        void Initialise(World* w, uint updateRate);
//        void SetMaterialBlock(uint x, uint y, uint z, uint width, uint height, uint depth, float amount, bool clear = true);
//        void ConvertToVoxels();
//        void SetColorForCell(uint x, uint y, uint z, float timeStep);
//        void AddMaterial(uint x, uint y, uint z, float amount);
//        void ClearMaterial(uint x, uint y, uint z);
//
//    private:
//        //Configuration
//        uint solveIterations = 1;
//        float timeStep = 0.01;
//        float brickTime = 0;
//        float advectTime = 0;
//        float velupdateTime = 0;
//        float divergenceupdatetime = 0;
//        float pressuresolvetime = 0;
//        float pressuregradienttime = 0;
//        float prevtime = 0;
//        int updates = 0;
//
//        Timer timer;
//        float simulationTime = 0;
//        int cellUpdates = 0;
//
//        vector<float3> ga;
//
//        uint GetBrickIDX(const uint x, const uint y, const uint z);
//        float GetData(const uint x, const uint y, const uint z, vector<float*>& data);
//        void SetData(const uint x, const uint y, const uint z, float v, vector<float*>& data);
//        void AddData(const uint x, const uint y, const uint z, float v, vector<float*>& data);
//        void EraseBrick(uint i);
//        void FreeBrick(uint i);
//        uint NewBrick(uint bx, uint by, uint bz);
//        void CheckCompressMemory();
//        void UpdateBricks();
//
//        //Brick addresses, or uint max if brick empty
//        uint* grid;
//        uint bricks_alive = 0;
//        uint bricks_allocated = 0;
//
//        //total mass of active bricks
//        vector<float> brick_m;
//        vector<bool> brick_static;
//
//        vector<uint> trash;
//        vector<uint> brick_x;
//        vector<uint> brick_y;
//        vector<uint> brick_z;
//
//        //Bricks containing all material data
//        vector<float*> m_bricks; // mass at t
//        vector<float*> m0_bricks; // // mass at t+1

//        vector<float*> p_bricks; // pressure at t
//        vector<float*> p0_bricks; // pressure at t+1

//        vector<float*> div_bricks; // divergence calc for t after advection, before t+1 is complete

//        vector<float*> vx_bricks; // velocity of x at t
//        vector<float*> vy_bricks; // velocity of y at t
//        vector<float*> vz_bricks; // velocity of z at t
//        vector<float*> vx0_bricks; // velocity of x at t+1
//        vector<float*> vy0_bricks; // velocity of y at t+1
//        vector<float*> vz0_bricks; // velocity of z at t+1

// MARK: SIMULATION DATA PER VOXEL

// - mass [Float]
// - pressure [Float]
// - divergence [Float] (temporary)
// - velocity, X [Float]
// - velocity, Y [Float]
// - velocity, Z [Float]

// MARK: SIMULATION FUNCTION DEFINITIONS

//        float TotalDivergence();
//        void PrintState();
//        float MaterialChange(uint x, uint y, uint z, float vxl, float vxr, float vyl, float vyr, float vzl, float vzr);
//        float IncomingMomentumX(uint x, uint y, uint z);
//        float IncomingMomentumY(uint x, uint y, uint z);
//        float IncomingMomentumZ(uint x, uint y, uint z);
//        bool IsCellStatic(uint x, uint y, uint z);
//        void CellVelocityUpdate(uint x, uint y, uint z, float timeStep);
//        void SolvePressure(uint x, uint y, uint z, float timeStep);
//        void CellDivergenceUpdate(uint x, uint y, uint z, float timeStep);
//        float TotalMass();
//        void MaterialAdvection(uint x, uint y, uint z, float timeStep);
//        void PressureGradient(uint x, uint y, uint z, float timeStep);
//        void RunOverAllBricks(CAPE* cape, void(CAPE::* func)(uint, uint, uint, float), float timeStep);
//    };
//
// }

// MARK: VOXEL LIBRARY EQUIVALENTS

// __forceinline uint CAPE::GetBrickIDX(const uint x, const uint y, const uint z)
// {
//    // calculate brick location in top-level grid
//    const uint bx = x / CAPE_BRICKDIM;
//    const uint by = y / CAPE_BRICKDIM;
//    const uint bz = z / CAPE_BRICKDIM;
//    if (bx >= CAPE_GRIDWIDTH || by >= CAPE_GRIDHEIGHT || bz >= CAPE_GRIDDEPTH) return UINT32_MAX;
//    const uint brickIdx = BIX(bx,by,bz);
//    return brickIdx;
// }

// __forceinline float CAPE::GetData(const uint x, const uint y, const uint z, vector<float*>& data)
// {
//    // obtain brick reference from top-level grid if brick does not exist, return "default" value
//    const uint bID = grid[GetBrickIDX(x, y, z)];
//    if (bID == UINT32_MAX) return 0;
//    float* d = data[bID];
//    const uint lx = x & (CAPE_BRICKDIM - 1), ly = y & (CAPE_BRICKDIM - 1), lz = z & (CAPE_BRICKDIM - 1);
//    return d[lx + ly * CAPE_BRICKDIM + lz * CAPE_BRICKDIM * CAPE_BRICKDIM];
// }

// __forceinline void CAPE::SetData(const uint x, const uint y, const uint z, float v, vector<float*>& data)
// {
//    const uint bID = grid[GetBrickIDX(x, y, z)];
//    if (bID == UINT32_MAX) return;
//    float* d = data[bID];
//    const uint lx = x & (CAPE_BRICKDIM - 1), ly = y & (CAPE_BRICKDIM - 1), lz = z & (CAPE_BRICKDIM - 1);
//    uint cellIdx = lx + ly * CAPE_BRICKDIM + lz * CAPE_BRICKDIM * CAPE_BRICKDIM;
//    d[cellIdx] = v;
// }

// __forceinline void CAPE::AddData(const uint x, const uint y, const uint z, float v, vector<float*>& data)
// {
//    const uint bID = grid[GetBrickIDX(x, y, z)];
//    if (bID == UINT32_MAX) return;
//    float* d = data[bID];
//    const uint lx = x & (CAPE_BRICKDIM - 1), ly = y & (CAPE_BRICKDIM - 1), lz = z & (CAPE_BRICKDIM - 1);
//    uint cellIdx = lx + ly * CAPE_BRICKDIM + lz * CAPE_BRICKDIM * CAPE_BRICKDIM;
//    d[cellIdx] += v;
// }

// MARK: SIMULATION SETUP

// Completely frees memory occupied by brick
// Costly because of erase (O(n)), but seems acceptable for now since this should be a rare opperation,
// only used to compress the active bricks vector when it becomes particularly sparse
// Faster solution would be a copy pass into a temporary buffer
// void CAPE::EraseBrick(uint i)
// {
//    //Free memory
//    free(vx_bricks[i]);
//    free(vy_bricks[i]);
//    free(vz_bricks[i]);
//    free(vx0_bricks[i]);
//    free(vy0_bricks[i]);
//    free(vz0_bricks[i]);
//    free(m0_bricks[i]);
//    free(m_bricks[i]);
//    free(p0_bricks[i]);
//    free(p_bricks[i]);
//
//    //Erase from brick vectors
//    brick_x.erase(brick_x.begin() + i);
//    brick_y.erase(brick_y.begin() + i);
//    brick_z.erase(brick_z.begin() + i);
//    brick_m.erase(brick_m.begin() + i);
//    brick_static.erase(brick_static.begin() + i);
//
//    //Erase pointers from brick vectors
//    vx_bricks.erase(vx_bricks.begin() + i);
//    vy_bricks.erase(vy_bricks.begin() + i);
//    vz_bricks.erase(vz_bricks.begin() + i);
//    vx0_bricks.erase(vx0_bricks.begin() + i);
//    vy0_bricks.erase(vy0_bricks.begin() + i);
//    vz0_bricks.erase(vz0_bricks.begin() + i);
//    m_bricks.erase(m_bricks.begin() + i);
//    m0_bricks.erase(m0_bricks.begin() + i);
//    p0_bricks.erase(p0_bricks.begin() + i);
//    p_bricks.erase(p_bricks.begin() + i);
// }

// Remove brick from active bricks buffer
// void CAPE::FreeBrick(uint i)
// {
//    uint brick_id = BIX(brick_x[i], brick_y[i], brick_z[i]);
//    bricks_alive--;
//    brick_x[i] = UINT32_MAX; //Mark as dead
//    trash.push_back(i);
//    grid[brick_id] = UINT32_MAX;//Unset brick adress in lookup table
// }

// Add brick to active brick buffer and create memory or reuse a dead brick
// uint CAPE::NewBrick(uint bx, uint by, uint bz)
// {
//    uint brick_addr = BIX(bx, by, bz);
//    uint bidx = UINT32_MAX;
//    if (trash.size() > 0) //reuse brick
//    {
//        bidx = trash[trash.size() - 1];
//        trash.pop_back();
//        grid[brick_addr] = bidx;
//        brick_x[bidx] = bx;
//        brick_y[bidx] = by;
//        brick_z[bidx] = bz;
//
//        //make sure crucial data is initialised to default values
//        brick_m[bidx] = 0;
//        brick_static[bidx] = bx == 0 || bx >= CAPE_GRIDWIDTH || by == 0 || by >= CAPE_GRIDHEIGHT || bz == 0 || bz >= CAPE_GRIDDEPTH;
//        memset(m0_bricks[bidx], 0, CAPE_BRICKSIZE * sizeof(float));
//    }
//    else //Create new brick memory
//    {
//        brick_x.push_back(bx);
//        brick_y.push_back(by);
//        brick_z.push_back(bz);
//
//        //Create buffers
//        vx_bricks.push_back((float*)calloc(CAPE_BRICKSIZE, sizeof(float)));
//        vy_bricks.push_back((float*)calloc(CAPE_BRICKSIZE, sizeof(float)));
//        vz_bricks.push_back((float*)calloc(CAPE_BRICKSIZE, sizeof(float)));
//        vx0_bricks.push_back((float*)calloc(CAPE_BRICKSIZE, sizeof(float)));
//        vy0_bricks.push_back((float*)calloc(CAPE_BRICKSIZE, sizeof(float)));
//        vz0_bricks.push_back((float*)calloc(CAPE_BRICKSIZE, sizeof(float)));
//
//        m0_bricks.push_back((float*)calloc(CAPE_BRICKSIZE, sizeof(float)));
//        m_bricks.push_back((float*)calloc(CAPE_BRICKSIZE, sizeof(float)));
//
//        brick_m.push_back(0);
//        brick_static.push_back(bx == 0 || bx >= CAPE_GRIDWIDTH || by == 0 || by >= CAPE_GRIDHEIGHT || bz == 0 || bz >= CAPE_GRIDDEPTH);
//        p0_bricks.push_back((float*)calloc(CAPE_BRICKSIZE, sizeof(float)));
//        p_bricks.push_back((float*)calloc(CAPE_BRICKSIZE, sizeof(float)));
//
//        //Set brick lookup in lookup table
//        bidx = m_bricks.size() - 1;
//        bricks_allocated = vx_bricks.size();
//        grid[brick_addr] = bidx;
//    }
//
//    bricks_alive++;
//    return bidx;
// }

// Initialises / deletes bricks no longer relevant in the simulation
// Is essentially a simple top level cellular automata, that checks every
// iteration if a brick is alive or dead, and will make neighbours alive if
// required, so that simulation data is always available, but empty regions do not
// take up any memory or require visits in update step.
// void CAPE::UpdateBricks()
// {
//    for (int i = 0; i < bricks_allocated; i++)
//    {
//        if (brick_x[i] != UINT32_MAX)
//        {
//            float bm = brick_m[i];
//
//            //Get brick location
//            uint bx = brick_x[i];
//            uint by = brick_y[i];
//            uint bz = brick_z[i];
//
//            //Check if neighbours exist
//            uint nbc = 0;
//            if (bm < MIN_BRICKMASS)
//            {
//                //if all existing neighbours have near 0 mass remove this brick
//                uint x0 = grid[BIX(bx - 1, by, bz)];
//                uint x1 = grid[BIX(bx + 1, by, bz)];
//                uint y0 = grid[BIX(bx, by - 1, bz)];
//                uint y1 = grid[BIX(bx, by + 1, bz)];
//                uint z0 = grid[BIX(bx, by, bz - 1)];
//                uint z1 = grid[BIX(bx, by, bz + 1)];
//
//                float mx0 = (x0 == UINT32_MAX ? 0 : brick_m[x0]);
//                float mx1 = (x1 == UINT32_MAX ? 0 : brick_m[x1]);
//                float my0 = (y0 == UINT32_MAX ? 0 : brick_m[y0]);
//                float my1 = (y1 == UINT32_MAX ? 0 : brick_m[y1]);
//                float mz0 = (z0 == UINT32_MAX ? 0 : brick_m[z0]);
//                float mz1 = (z1 == UINT32_MAX ? 0 : brick_m[z1]);
//
//                float nbm = mx0 + mx1 + my0 + my1 + mz0 + mz1;
//                if (nbm < MIN_BRICKMASS) FreeBrick(i);
//            }
//            else
//            {
//                //If any neighbour is not loaded, create it
//                if (grid[BIX(bx - 1, by, bz)] == UINT32_MAX) NewBrick(bx - 1, by, bz);
//                if (grid[BIX(bx + 1, by, bz)] == UINT32_MAX) NewBrick(bx + 1, by, bz);
//                if (grid[BIX(bx, by - 1, bz)] == UINT32_MAX) NewBrick(bx, by - 1, bz);
//                if (grid[BIX(bx, by + 1, bz)] == UINT32_MAX) NewBrick(bx, by + 1, bz);
//                if (grid[BIX(bx, by, bz - 1)] == UINT32_MAX) NewBrick(bx, by, bz - 1);
//                if (grid[BIX(bx, by, bz + 1)] == UINT32_MAX) NewBrick(bx, by, bz + 1);
//            }
//        }
//    }
//    for (int i = 0; i < bricks_allocated; i++)
//        brick_m[i] = 0; //Reset brick mass
//    CheckCompressMemory();     //Check and try to compress our brick vector if it becomes sparse
// }

// Check if we should compress memory (when we have many dead bricks not being recycled), e.g. most extreme case
// First and last block in buffer are alive, all others are dead. Helps prevent unnecessary brick visits
// There is a much faster way to do this, avoiding the vector.erase operation, but this is a pretty
// rare operation and generally the cost of this should not be relevant compared to the main update cycle.
// void CAPE::CheckCompressMemory()
// {
//    if (bricks_alive * 2 < bricks_allocated)
//    {
//        uint brick_idx = 0;
//        for (int i = 0; i < bricks_allocated; i++)
//        {
//            uint brick_addr = BIX(brick_x[i], brick_y[i], brick_z[i]);
//            if (brick_x[i] == UINT32_MAX) { EraseBrick(i--); bricks_allocated--; } //If dead brick, delete it's memory / r
//            grid[brick_addr] = i; //Update brick reference in grid
//        }
//    }
// }

// CAPE::~CAPE()
// {
//    //Delete bricks
//    for (int i = bricks_allocated - 1; i >= 0; i--)
//        EraseBrick(i);
//    free(grid);
// }

// Init memory and parameters
// void CAPE::Initialise(World* w, uint updateRate)
// {
//    world = w;
//    timer = Timer();
//    timeStep = 1.0f / updateRate;
//    if (GRAVITYENABLED == 1)
//        ga.push_back(float3(0, -9.81 * CELLSIZE, 0));
//
//    //Top level grid pointing to active bricks
//    grid = (uint*)(malloc(CAPE_GRIDSIZE * sizeof(uint)));
//    if(grid != nullptr) memset(grid, UINT32_MAX, CAPE_GRIDSIZE * sizeof(uint));
//
//    m_bricks = vector<float*>();
//    m0_bricks = vector<float*>();
//    p_bricks = vector<float*>();
//    p0_bricks = vector<float*>();
//    vx_bricks = vector<float*>();
//    vy_bricks = vector<float*>();
//    vz_bricks = vector<float*>();
//    vx0_bricks = vector<float*>();
//    vy0_bricks = vector<float*>();
//    vz0_bricks = vector<float*>();
// }

// void CAPE::ClearMaterial(uint x, uint y, uint z)
// {
//    if (grid[GetBrickIDX(x, y, z)] != UINT32_MAX)
//        SetData(x, y, z, 0, m0_bricks);
// }

// void CAPE::AddMaterial(uint x, uint y, uint z, float amount)
// {
//    //Add a single brick offset, to account for the layer of ghost bricks around the grid
//    //Similarly substract when indexing back to the worlds voxel space
//    x += CAPE_BRICKDIM;
//    y += CAPE_BRICKDIM;
//    z += CAPE_BRICKDIM;
//    uint brickIdx = GetBrickIDX(x, y, z);
//    uint brick_addr = grid[brickIdx];
//    if (brick_addr == UINT32_MAX)
//    {
//        const uint bx = x / CAPE_BRICKDIM;
//        const uint by = y / CAPE_BRICKDIM;
//        const uint bz = z / CAPE_BRICKDIM;
//        brick_addr = NewBrick(bx, by, bz);
//    }
//    AddData(x, y, z, amount, m0_bricks);
//    brick_m[brick_addr] += amount;
// }

// Writes a block of material of width w, height h, depth z starting at location x, y, z
// Won't overwrite world voxel if clear not true
// void CAPE::SetMaterialBlock(uint x0, uint y0, uint z0, uint w, uint h, uint d, float amount, bool clear)
// {
//    if (x0 + w > MAPWIDTH || y0 + h > MAPWIDTH || z0 + d > MAPWIDTH)
//    {
//        cout << "Block outside of grid" << endl;
//        return;
//    }
//    for(uint x = x0; x < x0 + w; x++)
//        for (uint y = y0; y < y0 + h; y++)
//            for (uint z = z0; z < z0 + d; z++)
//            {
//                uint v = world->Get(x, y, z);
//                if (clear)
//                {
//                    world->Set(x, y, z, 0);
//                    ClearMaterial(x, y, z);
//                    AddMaterial(x, y, z, amount);
//                }
//                else if(v == 0)
//                    AddMaterial(x, y, z, amount);
//            }
// }

// Update all bricks, if they are allocated, alive and non-static
// When using concurrency, assign a brick to each thread
// void CAPE::RunOverAllBricks(CAPE* cape, void (CAPE::* func)(uint, uint, uint, float), float timeStep)
// {
//    const size_t ac = bricks_allocated;
// #if USECONCURRENCY == 1
//    Concurrency::parallel_for(size_t(0), ac, [&](size_t i)
//        {
//            if (brick_x[i] != UINT32_MAX && !brick_static[i])
//            {
//                uint xo = brick_x[i] * CAPE_BRICKDIM;
//                uint yo = brick_y[i] * CAPE_BRICKDIM;
//                uint zo = brick_z[i] * CAPE_BRICKDIM;
//                for (int x = 0; x < CAPE_BRICKDIM; x++)
//                    for (int y = 0; y < CAPE_BRICKDIM; y++)
//                        for (int z = 0; z < CAPE_BRICKDIM; z++)
//                            (cape->*func)(xo + x, yo + y, zo + z, timeStep);
//            }
//        });
// #else
//    for (int i = 0; i < ac; i++)
//    {
//        if (brick_x[i] != UINT32_MAX && !brick_static[i])
//        {
//            uint xo = brick_x[i] * CAPE_BRICKDIM;
//            uint yo = brick_y[i] * CAPE_BRICKDIM;
//            uint zo = brick_z[i] * CAPE_BRICKDIM;
//            for (int x = 0; x < CAPE_BRICKDIM; x++)
//                for (int y = 0; y < CAPE_BRICKDIM; y++)
//                    for (int z = 0; z < CAPE_BRICKDIM; z++)
//                        (cape->*func)(xo + x, yo + y, zo + z, timeStep);
//        }
//    }
// #endif
// }

// MARK: SIMULATION FUNCTIONS

// MARK: SIM - STEP1

// PORTING_NOTES(heckj)
// `l` in variable typically references neg index (-1) neighbors
// `r` in variable typically references pos index (1) neighbors

// For the forward processing, the general flow is to read from a "current" state (m0, v0, etc)
// and write to a "new" state (m, v, etc). The code liberally does swaps of current/new data sets
// in the middle of the simulation, not at the end (all at once). It's important to pay attention
// to which data its reading, and where it's writing, and there's a little shimming of data into
// old state (velocities, in particular) to use in a future step.
// - advection writes into vx, vy, vz
// - then swap vx <-> vx0 - so for step two, the temp data is stashed in vx0, where it's read from
//   vx instead of normally reading from vx0.
// - in step 2, they already read both old and mass (which was flipped just before this step),
//   so m0 represents the new mass, and m represents the old mass during that step
//
// So:
// - step1: read from `m0`, write to `m`
//   stash temp momentum (outgoing) into `vx, vy, vz`
// - then flip `m` and `m0` (m0 now has new mass, m has old mass)
//   and flip `vx` and `vx0` (& y, z) (vx0, vy0, vz0 now has new/temp momentum, vx, vy, vz has old velocity)
// - step2: read omat from `m` and mat from `m0` - so `omat` is implying "old mass"
//   read vx+[l,c,r] from vx (old velocity data)
//   read om[x,y,z] from vx0 (temp momentum)
//   ultimately write into vx0, vy0, vz0 - the new momentum
// - step3: divergence update
//   read v[x,y,z]0 (new velocities)
//   read m0 (new mass), calculate divergence and write that into m[x,y,z] (what had been old mass)
// - step4: solve for pressure
//   p0 has old pressure, p has "new" pressure
//   multiple iterations letting the pressure values "average down", reading from p0, and writing to p
// - then SWAP p and p0 (p now has old pressure, p0 has new pressure)
// - step5: apply pressure gradient to adjust velocity
//   reads from p0 pressure (new), and ov[x,y,z]l from v[x,y,z]0 (new velocity)
//   calc acceleration and write into v[x,y,z] (a final new velocity)
// END OF SEQUENCE
// So at this point:
// - v[x,y,z] has final velocity
// - m has new mass
// - p has new pressure

// Step 1: Let all cells advect
//    RunOverAllBricks(this, &CAPE::MaterialAdvection, timeStep);
//    Swap(vx_bricks, vx0_bricks);
//    Swap(vy_bricks, vy0_bricks);
//    Swap(vz_bricks, vz0_bricks);
//    Swap(m_bricks, m0_bricks);

// Determine change in mass given current velocities
// Assume cells cannot go past maximum density (e.g 1), therefore clamp to 1.0
// float CAPE::MaterialChange(uint x, uint y, uint z, float vxl, float vxr, float vyl, float vyr, float vzl, float vzr)
// {
//    float mat   = GetData(x, y, z, m0_bricks);
//    float matxl = GetData(x - 1, y, z, m0_bricks);
//    float matyl = GetData(x, y - 1, z, m0_bricks);
//    float matzl = GetData(x, y, z - 1, m0_bricks);
//    float matxr = GetData(x + 1, y, z, m0_bricks);
//    float matyr = GetData(x, y + 1, z, m0_bricks);
//    float matzr = GetData(x, y, z + 1, m0_bricks);
//
//    float dxl = vxl < 0 ? vxl * min(1.0f, mat) : vxl * min(1.0f, matxl);
//    float dyl = vyl < 0 ? vyl * min(1.0f, mat) : vyl * min(1.0f, matyl);
//    float dzl = vzl < 0 ? vzl * min(1.0f, mat) : vzl * min(1.0f, matzl);
//    float dxr = vxr < 0 ? -vxr * min(1.0f, matxr) : -vxr * min(1.0f, mat);
//    float dyr = vyr < 0 ? -vyr * min(1.0f, matyr) : -vyr * min(1.0f, mat);
//    float dzr = vzr < 0 ? -vzr * min(1.0f, matzr) : -vzr * min(1.0f, mat);
//    return dxl + dyl + dzl + dxr + dyr + dzr;
// }

// Update material content of cell given velocities
// void CAPE::MaterialAdvection(uint x, uint y, uint z, float timeStep)
// {
//    float vxl = GetData(x, y, z, vx0_bricks) * AL; // damped velocity of this cell
//    float vyl = GetData(x, y, z, vy0_bricks) * AL;
//    float vzl = GetData(x, y, z, vz0_bricks) * AL;
//    float vxr = GetData(x + 1, y, z, vx0_bricks) * AL; // damped velocity of the pos neighbors
//    float vyr = GetData(x, y + 1, z, vy0_bricks) * AL;
//    float vzr = GetData(x, y, z + 1, vz0_bricks) * AL;
//
//    //node focussed advection
//    float mat = GetData(x, y, z, m0_bricks);
//    float matxl = GetData(x - 1, y, z, m0_bricks);   // l means neg index (1) neighbors
//    float matyl = GetData(x, y - 1, z, m0_bricks);
//    float matzl = GetData(x, y, z - 1, m0_bricks);
//    float matxr = GetData(x + 1, y, z, m0_bricks);   // r means pos index (1) neighbors
//    float matyr = GetData(x, y + 1, z, m0_bricks);
//    float matzr = GetData(x, y, z + 1, m0_bricks);
//
//    //Material movement in every direction == momentum
//    // maximum density assumed to be 1, so we cap the velocity to the maximum value from that
// direction...
//    float dxl = vxl < 0 ? vxl * min(1.0f, mat) : vxl * min(1.0f, matxl);
//    float dyl = vyl < 0 ? vyl * min(1.0f, mat) : vyl * min(1.0f, matyl);
//    float dzl = vzl < 0 ? vzl * min(1.0f, mat) : vzl * min(1.0f, matzl);
//    float dxr = vxr < 0 ? -vxr * min(1.0f, matxr) : -vxr * min(1.0f, mat);
//    float dyr = vyr < 0 ? -vyr * min(1.0f, matyr) : -vyr * min(1.0f, mat);
//    float dzr = vzr < 0 ? -vzr * min(1.0f, matzr) : -vzr * min(1.0f, mat);
//
//    //update incoming matter into current cell and outgoing matter neighbour cells
//    float nmat = mat + MaterialChange(x,y,z, vxl, vxr, vyl, vyr, vzl, vzr);
// #if DEBUG_MODE == 1
//    if (nmat < 0) cout << "negative mass! (timestep too high and or not using save MAXV?)" << endl;
// #endif
//    //Apply some evaporation and set new material
//    nmat = max(0.0f, nmat - EVAPORATION * timeStep);
//    SetData(x, y, z, nmat, m_bricks);
//
//    //Remember outgoing momentum (useful for velocity update)
//    //Store temporarily in unused velocity buffers
//    float om = min(0.0f, dxl) + min(0.0f, dyl) + min(0.0f, dzl)
//             + min(0.0f, dxr) + min(0.0f, dyr) + min(0.0f, dzr);
//    if (vxl < 0) SetData(x, y, z, vxl * om, vx_bricks);
//    if (vyl < 0) SetData(x, y, z, vyl * om, vy_bricks);
//    if (vzl < 0) SetData(x, y, z, vzl * om, vz_bricks);
//    if (vxr > 0) SetData(x + 1, y, z, vxr * om, vx_bricks);
//    if (vyr > 0) SetData(x, y + 1, z, vyr * om, vy_bricks);
//    if (vzr > 0) SetData(x, y, z + 1, vzr * om, vz_bricks);
//
//    //Add to total brick mass (for brick_updating step, assumes only 1 thread per brick active)
//    uint brickIdx = GetBrickIDX(x, y, z);
//    uint brick_addr = grid[brickIdx];
//    brick_m[brick_addr] += nmat;
// }

public struct MaterialAdvection: EvaluateStep {
    public typealias StorageType = FluidSimStorage

    public let name: String = "MaterialAdvection"
    public let scope: CARuleScope = .active

    public func evaluate(cell: CAIndex, deltaTime: Duration, storage0: StorageType, storage1: inout StorageType) -> CARuleResult {
        // Use the velocities stored in the current voxel to determine the amount of mass
        // moved, both left and right ( neg neighbors, pos neighbors ). To do this, we look
        // at the X, Y, and Z velocity in this cell, compute the ∂ momentum (mass * vel),
        // and sum up the incoming/outgoing flows to determine a new mass for this cell.

        let cell_flowX = storage0.fluidVelX[cell.index] * AL // damped velocity of this cell
        let cell_flowY = storage0.fluidVelY[cell.index] * AL // damped velocity of this cell
        let cell_flowZ = storage0.fluidVelZ[cell.index] * AL // damped velocity of this cell
        let cell_mass = storage0.fluidMass[cell.index]

        let cellxl_mass: Float = cell.xl > 0 ? storage0.fluidMass[cell.xl] : 0
        let cellyl_mass: Float = cell.yl > 0 ? storage0.fluidMass[cell.yl] : 0
        let cellzl_mass: Float = cell.zl > 0 ? storage0.fluidMass[cell.zl] : 0
        let cellxr_mass: Float = cell.xr > 0 ? storage0.fluidMass[cell.xr] : 0
        let cellyr_mass: Float = cell.yr > 0 ? storage0.fluidMass[cell.yr] : 0
        let cellzr_mass: Float = cell.zr > 0 ? storage0.fluidMass[cell.zr] : 0

        // Use the flow measurement of the cell to determine the amount of fluid moved.

        // The min(1.0, cell.volume) is a clamp to ensure that the flow is not greater than the volume
        // which is assuming that a volume of each voxel is 1, and that a fluid is NOT compressible
        // and density is 1.0, so volume and mass are effectively equivalent.

        // The flow value stored in the voxel location has a direction component indicated by its
        // sign, so a negative flow is moving towards the negative value on the axis. For that value,
        // we use the flow from this voxel. If the value is position, it's flowing to the positive direction
        // on the axis, so we need to ask the voxel in the negative direction what its flow is to compute
        // the amount that moves.

        // change in mass through the -X face
        let deltaMassXL = cell_flowX < 0 ? cell_flowX * min(1.0, cell_mass) : cell_flowX * min(1.0, cellxl_mass)
        // change in mass through the -Y face
        let deltaMassYL = cell_flowY < 0 ? cell_flowY * min(1.0, cell_mass) : cell_flowY * min(1.0, cellyl_mass)
        // change in mass through the -Z face
        let deltaMassZL = cell_flowZ < 0 ? cell_flowZ * min(1.0, cell_mass) : cell_flowZ * min(1.0, cellzl_mass)

        // change in mass through the X face
        let deltaMassXR = cell_flowX < 0 ? -cell_flowX * min(1.0, cellxr_mass) : -cell_flowX * min(1.0, cell_mass)
        // change in mass through the Y face
        let deltaMassYR = cell_flowY < 0 ? -cell_flowY * min(1.0, cellyr_mass) : -cell_flowY * min(1.0, cell_mass)
        // change in mass through the Z face
        let deltaMassZR = cell_flowZ < 0 ? -cell_flowZ * min(1.0, cellzr_mass) : -cell_flowZ * min(1.0, cell_mass)

        //    float dxl = vxl < 0 ? vxl * min(1.0f, mat) : vxl * min(1.0f, matxl);
        //    float dyl = vyl < 0 ? vyl * min(1.0f, mat) : vyl * min(1.0f, matyl);
        //    float dzl = vzl < 0 ? vzl * min(1.0f, mat) : vzl * min(1.0f, matzl);
        //    float dxr = vxr < 0 ? -vxr * min(1.0f, matxr) : -vxr * min(1.0f, mat);
        //    float dyr = vyr < 0 ? -vyr * min(1.0f, matyr) : -vyr * min(1.0f, mat);
        //    float dzr = vzr < 0 ? -vzr * min(1.0f, matzr) : -vzr * min(1.0f, mat);

        var newMass = cell_mass + deltaMassXL + deltaMassXR + deltaMassYL + deltaMassYR + deltaMassZL + deltaMassZR
        assert(newMass >= 0, "negative mass! (the time-step is too high and or not using save MAXV?)")
        //    //update incoming matter into current cell and outgoing matter neighbour cells
        //    float nmat = mat + MaterialChange(x,y,z, vxl, vxr, vyl, vyr, vzl, vzr);
        // #if DEBUG_MODE == 1
        //    if (nmat < 0) cout << "negative mass! (timestep too high and or not using save MAXV?)" << endl;
        // #endif

        // EVAPORATION
        // Apply some evaporation and set new material
        // clamp the evaporation so that mass never goes negative...
        //    nmat = max(0.0f, nmat - EVAPORATION * timeStep);
        //    SetData(x, y, z, nmat, m_bricks);
        newMass = max(0.0, newMass - EVAPORATION * deltaTime.inSeconds)
        storage1.fluidMass[cell.index] = newMass

        // Remember outgoing momentum (useful for velocity update)
        // Store temporarily in unused velocity buffers
        let outgoingMass = min(0.0, deltaMassXL) + min(0.0, deltaMassYL) + min(0.0, deltaMassZL) +
            min(0.0, deltaMassXR) + min(0.0, deltaMassYR) + min(0.0, deltaMassZR)

        if cell_flowX < 0 {
            storage1.fluidVelX[cell.index] = cell_flowX * outgoingMass
        } else {
            if cell.xr > 0 {
                storage1.fluidVelX[cell.xr] = cell_flowX * outgoingMass
            }
        }

        if cell_flowY < 0 {
            storage1.fluidVelY[cell.index] = cell_flowY * outgoingMass
        } else {
            if cell.yr > 0 {
                storage1.fluidVelY[cell.yr] = cell_flowY * outgoingMass
            }
        }
        if cell_flowZ < 0 {
            storage1.fluidVelZ[cell.index] = cell_flowZ * outgoingMass
        } else {
            if cell.zr > 0 {
                storage1.fluidVelZ[cell.zr] = cell_flowZ * outgoingMass
            }
        }

        //    float om = min(0.0f, dxl) + min(0.0f, dyl) + min(0.0f, dzl)
        //             + min(0.0f, dxr) + min(0.0f, dyr) + min(0.0f, dzr);
        //    if (vxl < 0) SetData(x, y, z, vxl * om, vx_bricks);
        //    if (vyl < 0) SetData(x, y, z, vyl * om, vy_bricks);
        //    if (vzl < 0) SetData(x, y, z, vzl * om, vz_bricks);
        //    if (vxr > 0) SetData(x + 1, y, z, vxr * om, vx_bricks); // cellxr_position
        //    if (vyr > 0) SetData(x, y + 1, z, vyr * om, vy_bricks); // cellyr_position
        //    if (vzr > 0) SetData(x, y, z + 1, vzr * om, vz_bricks); // cellzr_position

        return .indexUpdated
    }
}

// MARK: SIM - STEP2

// Step 2: Let all cells transition their velocity and apply global acceleration
//    RunOverAllBricks(this, &CAPE::CellVelocityUpdate, timeStep);

// Updates velocity by applying global acceleration and self-advection
// As with material advection, both sides of material are retrieved, even
// If not required (e.g. they get multiplied by 0), however since we are likely
// to visit a cell that does require this material, within the same brick, this
// should hopefully remain in cache, this allows us to keep a cell centric functional approach
// void CAPE::CellVelocityUpdate(uint x, uint y, uint z, float timeStep)
// {
//    //Load velocity and mass data so we can process momentum
//    float vxl = GetData(x - 1, y, z, vx_bricks) * AL;
//    float vyl = GetData(x, y - 1, z, vy_bricks) * AL;
//    float vzl = GetData(x, y, z - 1, vz_bricks) * AL;
//    float vxc = GetData(x, y, z, vx_bricks) * AL;
//    float vyc = GetData(x, y, z, vy_bricks) * AL;
//    float vzc = GetData(x, y, z, vz_bricks) * AL;
//    float vxr = GetData(x + 1, y, z, vx_bricks) * AL;
//    float vyr = GetData(x, y + 1, z, vy_bricks) * AL;
//    float vzr = GetData(x, y, z + 1, vz_bricks) * AL;
//
//    float omat = GetData(x, y, z, m_bricks);
//    float omatxl2 = GetData(x - 2, y, z, m_bricks);
//    float omatyl2 = GetData(x, y - 2, z, m_bricks);
//    float omatzl2 = GetData(x, y, z - 2, m_bricks);
//    float omatxl = GetData(x - 1, y, z, m_bricks);
//    float omatyl = GetData(x, y - 1, z, m_bricks);
//    float omatzl = GetData(x, y, z - 1, m_bricks);
//    float omatxr = GetData(x + 1, y, z, m_bricks);
//    float omatyr = GetData(x, y + 1, z, m_bricks);
//    float omatzr = GetData(x, y, z + 1, m_bricks);
//
//    float mat = GetData(x, y, z, m0_bricks);
//    float matxl = GetData(x - 1, y, z, m0_bricks);
//    float matyl = GetData(x, y - 1, z, m0_bricks);
//    float matzl = GetData(x, y, z - 1, m0_bricks);
//    float matxr = GetData(x + 1, y, z, m0_bricks);
//    float matyr = GetData(x, y + 1, z, m0_bricks);
//    float matzr = GetData(x, y, z + 1, m0_bricks);
//
//    float avxl = max(0.0f, vxl);
//    float avxr = min(0.0f, vxr);
//    float avxcl = max(0.0f, vxc);
//    float avxcr = min(0.0f, vxc);
//    float avyl = max(0.0f, vyl);
//    float avyr = min(0.0f, vyr);
//    float avycl = max(0.0f, vyc);
//    float avycr = min(0.0f, vyc);
//    float avzl = max(0.0f, vzl);
//    float avzr = min(0.0f, vzr);
//    float avzcl = max(0.0f, vzc);
//    float avzcr = min(0.0f, vzc);
//
//    //incoming colinear momentum across given axis
//    float imx = (avxl * avxl * omatxl2) - (avxr * avxr * omatxr);
//    float imy = (avyl * avyl * omatyl2) - (avyr * avyr * omatyr);
//    float imz = (avzl * avzl * omatzl2) - (avzr * avzr * omatzr);
//
//    //old momentum across axis
//    float mx0 = avxcl * omatxl + avxcr * omat;
//    float my0 = avycl * omatyl + avycr * omat;
//    float mz0 = avzcl * omatzl + avzcr * omat;
//
//    //outgoing momentum, stored temporarily during material advection step
//    float omx = GetData(x,y,z, vx0_bricks);
//    float omy = GetData(x, y, z, vy0_bricks);
//    float omz = GetData(x, y, z, vz0_bricks);
//
//    //Remaining momentum
//    float rmx = mx0 + omx;
//    float rmy = my0 + omy;
//    float rmz = mz0 + omz;
//
//    //New momentum = remainin momentum + incoming colinear momentum + incoming tangential momentum
//    float vcx = rmx + imx + IncomingMomentumX(x, y, z);
//    float vcy = rmy + imy + IncomingMomentumY(x, y, z);
//    float vcz = rmz + imz + IncomingMomentumZ(x, y, z);
//
//    //mass of source cell
//    float massx = vcx > 0 ? matxl : mat;
//    float massy = vcy > 0 ? matyl : mat;
//    float massz = vcz > 0 ? matzl : mat;
//
//    //New velocity *
//    float nvcx = massx == 0 ? 0 : vcx / massx * INVAL;
//    float nvcy = massy == 0 ? 0 : vcy / massy * INVAL;
//    float nvcz = massz == 0 ? 0 : vcz / massz * INVAL;
//
//    //Add global acceleration
//    for (int f = 0; f < ga.size(); f++)
//    {
//        nvcx += timeStep * ga[f].x;
//        nvcy += timeStep * ga[f].y;
//        nvcz += timeStep * ga[f].z;
//    }
//
//    //Check if not involving static cell, then finalise a valid velocity by clamping and dampening
//    bool staticc = IsCellStatic(x,y,z);
//    bool staticx = staticc || IsCellStatic(x - 1, y, z);
//    bool staticy = staticc || IsCellStatic(x, y - 1, z);
//    bool staticz = staticc || IsCellStatic(x, y, z - 1);
//
//    float nvx = !staticx * nvcx;
//    float nvy = !staticy * nvcy;
//    float nvz = !staticz * nvcz;
//    SetData(x, y, z, nvx, vx0_bricks);
//    SetData(x, y, z, nvy, vy0_bricks);
//    SetData(x, y, z, nvz, vz0_bricks);
// }

public struct VelocityUpdate: EvaluateStep {
    public typealias StorageType = FluidSimStorage

    public let name: String = "VelocityUpdate"
    public let scope: CARuleScope = .active

    // float CAPE::IncomingMomentumX(uint x, uint y, uint z)
    // {
    //    float yl = GetData(x, y - 1, z, vx_bricks);
    //    float yr = GetData(x, y + 1, z, vx_bricks);
    //
    //    //incoming for x across y axis
    //    float xym = -min(0.0f, GetData(x - 1, y + 1, z, vy_bricks)) * AL * GetData(x - 1, y + 1, z, m_bricks) * max(0.0f, yr) * AL //left above
    //        + max(0.0f, GetData(x - 1, y, z, vy_bricks)) * AL * GetData(x - 1, y - 1, z, m_bricks) * max(0.0f, yl) * AL//left below
    //        + -min(0.0f, GetData(x, y + 1, z, vy_bricks)) * AL * GetData(x, y + 1, z, m_bricks) * min(0.0f, yr) * AL //right above
    //        + max(0.0f, GetData(x, y, z, vy_bricks)) * AL * GetData(x, y - 1, z, m_bricks) * min(0.0f, yl) * AL; //right below

    //    float zl = GetData(x, y, z - 1, vx_bricks);
    //    float zr = GetData(x, y, z + 1, vx_bricks);
    //
    //    //incoming for x across z axis
    //    float xzm = -min(0.0f, GetData(x - 1, y, z + 1, vz_bricks)) * AL * GetData(x - 1, y, z + 1, m_bricks) * max(0.0f, zr) * AL //left above
    //        + max(0.0f, GetData(x - 1, y, z, vz_bricks)) * AL * GetData(x - 1, y, z - 1, m_bricks) * max(0.0f, zl) * AL//left below
    //        + -min(0.0f, GetData(x, y, z + 1, vz_bricks)) * AL * GetData(x, y, z + 1, m_bricks) * min(0.0f, zr) * AL //right above
    //        + max(0.0f, GetData(x, y, z, vz_bricks)) * AL * GetData(x, y, z - 1, m_bricks) * min(0.0f, zl) * AL; //right below
    //    return xym + xzm;
    // }

//    func incomingMomentumX(cell: CAIndex, storage0: StorageType) -> Float {
//        let yl_momentum: Float = cell.yl > 0 ? storage0.fluidVelX[cell.yl] : 0.0
//        let yr_momentum: Float = cell.yr > 0 ? storage0.fluidVelX[cell.yr] : 0.0
//
//        // incoming for x across y axis
//        let xym: Float = -min(0.0, storage0.fluidVelY[cell.xl_yr]) * AL * storage0.fluidMass[cell.xl_yr] * max(0.0, yr_momentum) * AL
//            // left above
//
//        + max(0.0, storage0.fluidVelY[cell.xl]) * AL * storage0.fluidMass[yl_position] * max(0.0, yl_momentum) * AL
//            // left below
//
//        + -min(0.0, storage0.fluidVelY[cell.yr]) * AL * storage0.fluidMass[yr_position] * min(0.0, yr_momentum) * AL
//            // right above
//
//        + max(0.0, storage0.fluidVelY[cell.index]) * AL * storage0.fluidMass[yl_position] * min(0.0, yl_momentum) * AL
//        // right below
//
//        let zl_momentum: Float = cell.zl > 0 ? storage0.fluidVelX[cell.zl] : 0.0
//        let zr_momentum: Float = cell.zr > 0 ? storage0.fluidVelX[cell.zr] : 0.0
//
//        //    float zl = GetData(x, y, z - 1, vx_bricks);
//        //    float zr = GetData(x, y, z + 1, vx_bricks);
//        //    //incoming for x across z axis
//        //    float xzm = -min(0.0f, GetData(x - 1, y, z + 1, vz_bricks)) * AL * GetData(x - 1, y, z + 1, m_bricks) * max(0.0f, zr) * AL //left above
//        //        + max(0.0f, GetData(x - 1, y, z, vz_bricks)) * AL * GetData(x - 1, y, z - 1, m_bricks) * max(0.0f, zl) * AL//left below
//        //        + -min(0.0f, GetData(x, y, z + 1, vz_bricks)) * AL * GetData(x, y, z + 1, m_bricks) * min(0.0f, zr) * AL //right above
//        //        + max(0.0f, GetData(x, y, z, vz_bricks)) * AL * GetData(x, y, z - 1, m_bricks) * min(0.0f, zl) * AL; //right below
//        //    return xym + xzm;
//    }

    public func evaluate(cell: CAIndex, deltaTime _: Duration, storage0: StorageType, storage1: inout StorageType) -> CARuleResult {
        // Load velocity and mass data so we can process momentum
        let vxl = storage0.fluidVelX[cell.xl] // * AL
        let vyl = storage0.fluidVelY[cell.yl] // * AL
        let vzl = storage0.fluidVelZ[cell.zl] // * AL
        let vx = storage0.fluidVelX[cell.index] // * AL
        let vy = storage0.fluidVelY[cell.index] // * AL
        let vz = storage0.fluidVelZ[cell.index] // * AL
        let vxr = storage0.fluidVelX[cell.xr] // * AL
        let vyr = storage0.fluidVelY[cell.yr] // * AL
        let vzr = storage0.fluidVelZ[cell.zr] // * AL

        // load in outgoing mass remembered from the advection step
        let outgoingmass = storage1.fluidMass[cell.index]
        let outgoingmass_xl = storage1.fluidMass[cell.xl]
        let outgoingmass_yl = storage1.fluidMass[cell.yl]
        let outgoingmass_zl = storage1.fluidMass[cell.zl]
        let outgoingmass_xl2 = storage1.fluidMass[cell.xl2]
        let outgoingmass_yl2 = storage1.fluidMass[cell.yl2]
        let outgoingmass_zl2 = storage1.fluidMass[cell.zl2]
        let outgoingmass_xr = storage1.fluidMass[cell.xr]
        let outgoingmass_yr = storage1.fluidMass[cell.yr]
        let outgoingmass_zr = storage1.fluidMass[cell.zr]

        let mass = storage0.fluidMass[cell.index]
        let mass_xl = storage0.fluidMass[cell.xl]
        let mass_yl = storage0.fluidMass[cell.yl]
        let mass_zl = storage0.fluidMass[cell.zl]
        let mass_xr = storage0.fluidMass[cell.xr]
        let mass_yr = storage0.fluidMass[cell.yr]
        let mass_zr = storage0.fluidMass[cell.zr]

        // calculate clamped advection numbers to use in colinear momentum calculations
        let avxl = max(0.0, vxl)
        let avxr = min(0.0, vxr)
        let avxcl = max(0.0, vx)
        let avxcr = min(0.0, vx)
        let avyl = max(0.0, vyl)
        let avyr = min(0.0, vyr)
        let avycl = max(0.0, vy)
        let avycr = min(0.0, vy)
        let avzl = max(0.0, vzl)
        let avzr = min(0.0, vzr)
        let avzcl = max(0.0, vz)
        let avzcr = min(0.0, vz)

        // incoming colinear momentum across given axis
        let imx = (avxl * avxl * outgoingmass_xl2) - (avxr * avxr * outgoingmass_xr)
        let imy = (avyl * avyl * outgoingmass_yl2) - (avyr * avyr * outgoingmass_yr)
        let imz = (avzl * avzl * outgoingmass_zl2) - (avzr * avzr * outgoingmass_zr)

        // old momentum across axis
        let mx0 = avxcl * outgoingmass_xl + avxcr * outgoingmass
        let my0 = avycl * outgoingmass_yl + avycr * outgoingmass
        let mz0 = avzcl * outgoingmass_zl + avzcr * outgoingmass

        // outgoing momentum, stored temporarily during material advection step
        let omx = storage1.fluidVelX[cell.index]
        let omy = storage1.fluidVelY[cell.index]
        let omz = storage1.fluidVelZ[cell.index]

        // Remaining momentum
        let rmx = mx0 + omx
        let rmy = my0 + omy
        let rmz = mz0 + omz

        // New momentum = remainin momentum + incoming colinear momentum + incoming tangential momentum
        let vcx = rmx + imx // + IncomingMomentumX(x, y, z);
        let vcy = rmy + imy // + IncomingMomentumY(x, y, z);
        let vcz = rmz + imz // + IncomingMomentumZ(x, y, z);

        //    float vcx = rmx + imx + IncomingMomentumX(x, y, z);
        //    float vcy = rmy + imy + IncomingMomentumY(x, y, z);
        //    float vcz = rmz + imz + IncomingMomentumZ(x, y, z);
        //
        //    //mass of source cell
        //    float massx = vcx > 0 ? matxl : mat;
        //    float massy = vcy > 0 ? matyl : mat;
        //    float massz = vcz > 0 ? matzl : mat;
        //
        //    //New velocity *
        //    float nvcx = massx == 0 ? 0 : vcx / massx * INVAL;
        //    float nvcy = massy == 0 ? 0 : vcy / massy * INVAL;
        //    float nvcz = massz == 0 ? 0 : vcz / massz * INVAL;
        //
        //    //Add global acceleration
        //    for (int f = 0; f < ga.size(); f++)
        //    {
        //        nvcx += timeStep * ga[f].x;
        //        nvcy += timeStep * ga[f].y;
        //        nvcz += timeStep * ga[f].z;
        //    }
        //
        //    //Check if not involving static cell, then finalise a valid velocity by clamping and dampening
        //    bool staticc = IsCellStatic(x,y,z);
        //    bool staticx = staticc || IsCellStatic(x - 1, y, z);
        //    bool staticy = staticc || IsCellStatic(x, y - 1, z);
        //    bool staticz = staticc || IsCellStatic(x, y, z - 1);
        //
        //    float nvx = !staticx * nvcx;
        //    float nvy = !staticy * nvcy;
        //    float nvz = !staticz * nvcz;
        //    SetData(x, y, z, nvx, vx0_bricks);
        //    SetData(x, y, z, nvy, vy0_bricks);
        //    SetData(x, y, z, nvz, vz0_bricks);

        return .indexUpdated
    }
}

// MARK: SIM - STEP3

// Step 3: Determine expected divergence with new velocities
//    RunOverAllBricks(this, &CAPE::CellDivergenceUpdate, timeStep);
//

// Calculate and set divergence of a cell we need to solve pressure for
// void CAPE::CellDivergenceUpdate(uint x, uint y, uint z, float timeStep)
// {
//    SetData(x, y, z, 0, m_bricks);
//    SetData(x, y, z, 0, p0_bricks);
//    float vxl = GetData(x, y, z, vx0_bricks) * AL;
//    float vyl = GetData(x, y, z, vy0_bricks) * AL;
//    float vzl = GetData(x, y, z, vz0_bricks) * AL;
//    float vxr = GetData(x + 1, y, z, vx0_bricks) * AL;
//    float vyr = GetData(x, y + 1, z, vy0_bricks) * AL;
//    float vzr = GetData(x, y, z + 1, vz0_bricks) * AL;
//
//    float mc = MaterialChange(x, y, z, vxl, vxr, vyl, vyr, vzl, vzr); //divergence = amount of mass over 1 and under 0
//    float div = (GetData(x, y, z, m0_bricks) + mc - 1.0f) * 2.0f; //new mass, premultiply by 2 to prevent gradient division
//    //Store in temporarily unused material buffer
//    SetData(x, y, z, div, m_bricks);
// }

// MARK: SIM - STEP4

// Step 4: Solve for a pressure that will prevent divergence
//    for (int i = 0; i < PRESSURE_ITERATIONS; i++)
//    {
//        RunOverAllBricks(this, &CAPE::SolvePressure, timeStep);
//        Swap(p_bricks, p0_bricks);
//    }

// Determine a suitable pressure value that prevents divergence, given
// the cells divergence, and a best estimation of the pressure of neighbours
// Repeatedly calling this improves this estimation
// void CAPE::SolvePressure(uint x, uint y, uint z, float timeStep)
// {
//    float div = GetData(x, y, z, m_bricks);
//    float nbp = 0;
//    float k = 0;
//    nbp += max(0.0f, GetData(x + 1, y, z, p0_bricks));
//    nbp += max(0.0f, GetData(x - 1, y, z, p0_bricks));
//    nbp += max(0.0f, GetData(x, y + 1, z, p0_bricks));
//    nbp += max(0.0f, GetData(x, y - 1, z, p0_bricks));
//    nbp += max(0.0f, GetData(x, y, z + 1, p0_bricks));
//    nbp += max(0.0f, GetData(x, y, z - 1, p0_bricks));
//
//    k += (IsCellStatic(x + 1, y, z) == 0);
//    k += (IsCellStatic(x - 1, y, z) == 0);
//    k += (IsCellStatic(x, y + 1, z) == 0);
//    k += (IsCellStatic(x, y - 1, z) == 0);
//    k += (IsCellStatic(x, y, z + 1) == 0);
//    k += (IsCellStatic(x, y, z - 1) == 0);
//
//    float np = (div + nbp) / k;
//    SetData(x, y, z, np, p_bricks);
// }

// STEP4: Solve for pressure that prevents divergence
struct Pressure: EvaluateStep {
    typealias StorageType = FluidSimStorage

    public let name: String = "SolvePressure"
    public let scope: CARuleScope = .active

    func evaluate(cell: CAIndex, deltaTime _: Duration, storage0: StorageType, storage1: inout StorageType) -> CARuleResult {
        // Determine a suitable pressure value that prevents divergence, given
        // the cells divergence, and a best estimation of the pressure of neighbors
        // Repeatedly calling this improves this estimation

        let thisVoxel: FluidSimCell = storage0.voxelAt(cell.index)
        let div = thisVoxel.volume
        var neighborPressure: Float = 0
        var k: Float = 0
        for neighborLinearIndex in storage0.bounds.neighborsInBounds(of: cell.index) {
            let voxelData = storage0.voxelAt(neighborLinearIndex)
            neighborPressure += max(0.0, voxelData.pressure)
            k += voxelData.volume
        }
        let estimatedPressure = (div + neighborPressure) / k
        storage1.fluidPressure[cell.index] = estimatedPressure
        return .indexUpdated
    }
}

// MARK: SIM - STEP5

// Step 5: Apply pressure gradient to correct velocity
//    RunOverAllBricks(this, &CAPE::PressureGradient, timeStep);
//    Swap(vx_bricks, vx0_bricks);
//    Swap(vy_bricks, vy0_bricks);
//    Swap(vz_bricks, vz0_bricks);

// Determine pressure gradient and apply to correct velocities
// void CAPE::PressureGradient(uint x, uint y, uint z, float timeStep)
// {
//    //solid cells do not experience pressure
//    if (IsCellStatic(x,y,z))
//        return;
//
//    float m = GetData(x, y, z, m0_bricks);
//    float cellPressure = max(0.0f, GetData(x,y,z, p0_bricks));
//
//    //No pressure gradient to solid cells, therefore simply set to equal pressure
//    float ovxl = GetData(x, y, z, vx0_bricks);
//    float ovyl = GetData(x, y, z, vy0_bricks);
//    float ovzl = GetData(x, y, z, vz0_bricks);
//    float leftPressure = max(0.0f, IsCellStatic(x - 1, y, z) ? cellPressure : GetData(x - 1, y, z, p0_bricks));
//    float botPressure = max(0.0f, IsCellStatic(x, y - 1, z) ? cellPressure : GetData(x, y - 1,z, p0_bricks));
//    float backPressure = max(0.0f, IsCellStatic(x, y, z - 1) ? cellPressure : GetData(x, y, z - 1, p0_bricks));
//
//    //Determine acceleration from pressure gradient
//    //Since we are also finalising the velocity for the current update here, we want to dampen
//    //the original remaining velocity and clamp the velocity so we do not exceed the maximum here
//    float dampen = 1 - VELOCITY_DAMPENING * timeStep;
//    float vxa = leftPressure - cellPressure;
//    float vya = botPressure - cellPressure;
//    float vza = backPressure - cellPressure;
//    float vxl = ovxl * dampen + vxa;
//    float vyl = ovyl * dampen + vya;
//    float vzl = ovzl * dampen + vza;
//    SetData(x, y, z, clamp(vxl, -MAXV, MAXV), vx_bricks);
//    SetData(x, y, z, clamp(vyl, -MAXV, MAXV), vy_bricks);
//    SetData(x, y, z, clamp(vzl, -MAXV, MAXV), vz_bricks);
// }

// Is the cell active in the simulation:
// False if it is a voxel existing in the world
// but no material is defined for it, or the brick
// that it is in is marked static.
// bool CAPE::IsCellStatic(uint x, uint y, uint z)
// {
//    // calculate brick location in top-level grid
//    uint brickIDX = GetBrickIDX(x, y, z);
//    uint brick_addr = grid[brickIDX];
//    if (brick_addr == UINT32_MAX)
//        return true;
//
//    bool static_brick = brick_static[brick_addr];
//    float mass = GetData(x, y, z, m0_bricks);
//    return (mass == 0 && world->Get(x - CAPE_BRICKDIM, y - CAPE_BRICKDIM, z - CAPE_BRICKDIM) != 0) || static_brick;
// }

// MARK: CENTRAL SIMULATION UPDATE

// Performs a single update - also maintains timers and calls print function
// void CAPE::Tick(float deltaTime)
// {
//    updates++;
//    timer.reset();
//    cellUpdates = 0;
//
//    prevtime = 0;
//    UpdateBricks();
//    brickTime += timer.elapsed() - prevtime;
//    prevtime = timer.elapsed();
//
//    //Step 1: Let all cells advect
//    RunOverAllBricks(this, &CAPE::MaterialAdvection, timeStep);
//    Swap(vx_bricks, vx0_bricks);
//    Swap(vy_bricks, vy0_bricks);
//    Swap(vz_bricks, vz0_bricks);
//    Swap(m_bricks, m0_bricks);
//
//    advectTime += timer.elapsed() - prevtime;
//    prevtime = timer.elapsed();
//
//    //Step 2: Let all cells transition their velocity and apply global acceleration
//    RunOverAllBricks(this, &CAPE::CellVelocityUpdate, timeStep);
//
//    velupdateTime += timer.elapsed() - prevtime;
//    prevtime = timer.elapsed();
//
//    //Step 3: Determine expected divergence with new velocities
//    RunOverAllBricks(this, &CAPE::CellDivergenceUpdate, timeStep);
//
//    divergenceupdatetime += timer.elapsed() - prevtime;
//    prevtime = timer.elapsed();
//
//    //Step 4: Solve for a pressure that will prevent divergence
//    for (int i = 0; i < PRESSURE_ITERATIONS; i++)
//    {
//        RunOverAllBricks(this, &CAPE::SolvePressure, timeStep);
//        Swap(p_bricks, p0_bricks);
//    }
//
//    pressuresolvetime += timer.elapsed() - prevtime;
//    prevtime = timer.elapsed();
//
//    //Step 5: Apply pressure gradient to correct velocity
//    RunOverAllBricks(this, &CAPE::PressureGradient, timeStep);
//    Swap(vx_bricks, vx0_bricks);
//    Swap(vy_bricks, vy0_bricks);
//    Swap(vz_bricks, vz0_bricks);
//
//    pressuregradienttime += timer.elapsed() - prevtime;
//    prevtime = timer.elapsed();
//
//    simulationTime = timer.elapsed();
//
//    PrintState();
// }

// Retrieves amount of incoming momentum on the X-axis from tangential moving material across the y and z axis
// float CAPE::IncomingMomentumX(uint x, uint y, uint z)
// {
//    float yl = GetData(x, y - 1, z, vx_bricks);
//    float yr = GetData(x, y + 1, z, vx_bricks);
//    //incoming for x across y axis
//    float xym = -min(0.0f, GetData(x - 1, y + 1, z, vy_bricks)) * AL * GetData(x - 1, y + 1, z, m_bricks) * max(0.0f, yr) * AL //left above
//        + max(0.0f, GetData(x - 1, y, z, vy_bricks)) * AL * GetData(x - 1, y - 1, z, m_bricks) * max(0.0f, yl) * AL//left below
//        + -min(0.0f, GetData(x, y + 1, z, vy_bricks)) * AL * GetData(x, y + 1, z, m_bricks) * min(0.0f, yr) * AL //right above
//        + max(0.0f, GetData(x, y, z, vy_bricks)) * AL * GetData(x, y - 1, z, m_bricks) * min(0.0f, yl) * AL; //right below
//    float zl = GetData(x, y, z - 1, vx_bricks);
//    float zr = GetData(x, y, z + 1, vx_bricks);
//    //incoming for x across z axis
//    float xzm = -min(0.0f, GetData(x - 1, y, z + 1, vz_bricks)) * AL * GetData(x - 1, y, z + 1, m_bricks) * max(0.0f, zr) * AL //left above
//        + max(0.0f, GetData(x - 1, y, z, vz_bricks)) * AL * GetData(x - 1, y, z - 1, m_bricks) * max(0.0f, zl) * AL//left below
//        + -min(0.0f, GetData(x, y, z + 1, vz_bricks)) * AL * GetData(x, y, z + 1, m_bricks) * min(0.0f, zr) * AL //right above
//        + max(0.0f, GetData(x, y, z, vz_bricks)) * AL * GetData(x, y, z - 1, m_bricks) * min(0.0f, zl) * AL; //right below
//    return xym + xzm;
// }

// Retrieves amount of incoming momentum on the Y-axis from tangential moving material across the x and z axis
// float CAPE::IncomingMomentumY(uint x, uint y, uint z)
// {
//    float xl = GetData(x - 1, y, z, vy_bricks);
//    float xr = GetData(x + 1, y, z, vy_bricks);
//    //incoming for x across y axis
//    float yxm = -min(0.0f, GetData(x + 1, y - 1, z, vx_bricks)) * AL * GetData(x + 1, y - 1, z, m_bricks) * max(0.0f, xr) * AL //left above
//        + max(0.0f, GetData(x, y - 1, z, vx_bricks)) * AL * GetData(x - 1, y - 1, z, m_bricks) * max(0.0f, xl) * AL//left below
//        + -min(0.0f, GetData(x + 1, y, z, vx_bricks)) * AL * GetData(x + 1, y, z, m_bricks) * min(0.0f, xr) * AL //right above
//        + max(0.0f, GetData(x, y, z, vx_bricks)) * AL * GetData(x - 1, y, z, m_bricks) * min(0.0f, xl) * AL; //right below
//
//    float zl = GetData(x, y, z - 1, vy_bricks);
//    float zr = GetData(x, y, z + 1, vy_bricks);
//    //incoming for x across z axis
//    float yzm = -min(0.0f, GetData(x, y - 1, z + 1, vz_bricks)) * AL * GetData(x, y - 1, z + 1, m_bricks) * max(0.0f, zr) * AL //left above
//        + max(0.0f, GetData(x, y - 1, z, vz_bricks)) * AL * GetData(x, y - 1, z - 1, m_bricks) * max(0.0f, zl) * AL//left below
//        + -min(0.0f, GetData(x, y, z + 1, vz_bricks)) * AL * GetData(x, y, z + 1, m_bricks) * min(0.0f, zr) * AL //right above
//        + max(0.0f, GetData(x, y, z, vz_bricks)) * AL * GetData(x, y, z - 1, m_bricks) * min(0.0f, zl) * AL; //right below
//    return yxm + yzm;
// }

// Retrieves amount of incoming momentum on the Z-axis from tangential moving material across the x and y axis
// float CAPE::IncomingMomentumZ(uint x, uint y, uint z)
// {
//    float xl = GetData(x - 1, y, z, vz_bricks);
//    float xr = GetData(x + 1, y, z, vz_bricks);
//    //incoming for x across y axis
//    float zxm = -min(0.0f, GetData(x + 1, y, z - 1, vx_bricks)) * AL * GetData(x + 1, y, z - 1, m_bricks) * max(0.0f, xr) * AL //left above
//        + max(0.0f, GetData(x, y, z - 1, vx_bricks)) * AL * GetData(x - 1, y, z - 1, m_bricks) * max(0.0f, xl) * AL//left below
//        + -min(0.0f, GetData(x + 1, y, z, vx_bricks)) * AL * GetData(x + 1, y, z, m_bricks) * min(0.0f, xr) * AL //right above
//        + max(0.0f, GetData(x, y, z, vx_bricks)) * AL * GetData(x - 1, y, z, m_bricks) * min(0.0f, xl) * AL; //right below
//
//    float yl = GetData(x, y - 1, z, vz_bricks);
//    float yr = GetData(x, y + 1, z, vz_bricks);
//    //incoming for x across z axis
//    float zym = -min(0.0f, GetData(x, y + 1, z - 1, vy_bricks)) * AL * GetData(x, y + 1, z - 1, m_bricks) * max(0.0f, yr) * AL //left above
//        + max(0.0f, GetData(x, y, z - 1, vy_bricks)) * AL * GetData(x, y - 1, z - 1, m_bricks) * max(0.0f, yl) * AL//left below
//        + -min(0.0f, GetData(x, y + 1, z, vy_bricks)) * AL * GetData(x, y + 1, z, m_bricks) * min(0.0f, yr) * AL //right above
//        + max(0.0f, GetData(x, y, z, vy_bricks)) * AL * GetData(x, y - 1, z, m_bricks) * min(0.0f, yl) * AL; //right below
//    return zxm + zym;
// }

// Converts simulation data to actual voxels placed in the world
// void CAPE::ConvertToVoxels()
// {
//    RunOverAllBricks(this, &CAPE::SetColorForCell, timeStep);
// }

// Converts rgb value to the 4-4-4 12 bit rgb format used
// uint LerpToRGB(float r, float g, float b)
// {
//    r = clamp(r, 0.0f, 1.0f);
//    g = clamp(g, 0.0f, 1.0f);
//    b = clamp(b, 0.0f, 1.0f);
//    return (uint)(15 * b) + ((uint)(15 * g) << 4) + ((uint)(15 * r) << 8);
// }

// Converts cell state to a color and sets it into the world
// void CAPE::SetColorForCell(uint x, uint y, uint z, float timeStep)
// {
//    uint color = 0;
//    float mass = GetData(x,y,z, m0_bricks);
//    if (mass > 0.0001)
//    {
//        //interpolate mass between 0 and - max mass for the 15 different colors.
//        float mass = GetData(x, y, z, m0_bricks);
//        float diffFromEmpty = 1 - clamp(1 - mass, 0.0f, 1.0f);
//        if (diffFromEmpty < MINRENDERMASS)
//            world->Set(x - CAPE_BRICKDIM, y - CAPE_BRICKDIM, z - CAPE_BRICKDIM, 0);
//        else
//        {
//            float b = 1 - diffFromEmpty / 2.0f + 0.5f;
//            float g = diffFromEmpty > 0.5f ? 1 - (diffFromEmpty - 0.5f) : 1;
//            world->Set(x - CAPE_BRICKDIM, y - CAPE_BRICKDIM, z - CAPE_BRICKDIM, LerpToRGB(0, g, b));
//        }
//    }
// }

// Print simulation debug information
// void CAPE::PrintState()
// {
//    system("cls");
//    cout << "Timestep: " << timeStep << endl;
//    float mass = TotalMass();
//    cout << "Total Mass in System: " << mass << endl;
//    float divergence = TotalDivergence();
//    cout << "Total divergence: " << divergence << " which is " << 100 * divergence / (mass - divergence) << "%" << endl;
//    cout << "Elapsed Simulation Time: " << simulationTime << endl;
//    cout << "brick update time " << brickTime / updates << endl;
//    cout << "advection time " << advectTime / updates << endl;
//    cout << "vel update time " << velupdateTime / updates << endl;
//    cout << "divergence time " << divergenceupdatetime / updates << endl;
//    cout << "pressure solve time " << pressuresolvetime / updates << endl;
//    cout << "pressure gradient time " << pressuregradienttime / updates << endl;
//    cout << "Simulations per Second: " << 1 / simulationTime << endl;
//    cout << "Alive Bricks: " << bricks_alive << endl;
//    cout << "Allocated Bricks: " << bricks_allocated << endl;
//    cout << "Active Cells: " << bricks_alive * CAPE_BRICKSIZE << endl;
//    cout << "Cells updated per second: " << bricks_alive * CAPE_BRICKSIZE / simulationTime << endl;
// }

// Some functions that aggregate simulation data for debugging
// float CAPE::TotalDivergence()
// {
//    float divergence = 0;
//    for (int i = 0; i < bricks_allocated; i++)
//    {
//        if (brick_x[i] != UINT32_MAX)
//        {
//            uint xo = brick_x[i] * CAPE_BRICKDIM;
//            uint yo = brick_y[i] * CAPE_BRICKDIM;
//            uint zo = brick_z[i] * CAPE_BRICKDIM;
//            for (int x = 0; x < CAPE_BRICKDIM; x++)
//                for (int y = 0; y < CAPE_BRICKDIM; y++)
//                    for (int z = 0; z < CAPE_BRICKDIM; z++)
//                        divergence += max(0.0f, GetData(xo + x, yo + y, zo + z, m0_bricks) - 1);
//        }
//    }
//    return divergence;
// }

// float CAPE::TotalMass()
// {
//    float totalMass = 0;
//    for (int i = 0; i < bricks_allocated; i++)
//    {
//        if (brick_x[i] != UINT32_MAX)
//        {
//            uint xo = brick_x[i] * CAPE_BRICKDIM;
//            uint yo = brick_y[i] * CAPE_BRICKDIM;
//            uint zo = brick_z[i] * CAPE_BRICKDIM;
//            for (int x = 0; x < CAPE_BRICKDIM; x++)
//                for (int y = 0; y < CAPE_BRICKDIM; y++)
//                    for (int z = 0; z < CAPE_BRICKDIM; z++)
//                        totalMass += GetData(xo + x, yo + y, zo + z, m0_bricks);
//        }
//    }
//    return totalMass;
// }
