# CAD, 3D Representations, and 3D Editing Software Literature Review

## Scope

This note covers three overlapping areas:

1. Core 3D representations used in CAD and modeling systems
2. Editing paradigms and software ecosystems built on top of those representations
3. Recent research directions that try to bridge geometric modeling, procedural design, and AI

The emphasis is practical. I am not treating "3D" as one thing. The representation chosen by a system determines what kinds of editing are easy, robust, precise, or impossible.

## Why Representation Matters

There is no universal best representation for 3D. Different workflows optimize for different goals:

- engineering precision
- manufacturability
- visual realism
- sculptability
- procedural control
- simulation compatibility
- edit robustness
- compactness and interchange

Many frustrations people have with CAD or 3D tools are representation problems disguised as UI problems.

Examples:

- fillets and shell operations fail in B-rep systems because of topology and tolerance issues
- meshes are easy to render and sculpt but awkward to dimension or manufacture directly
- implicit fields are robust for lattices and topology optimization but awkward for traditional drafting
- CSG is concise and programmable but often too weak for detailed downstream editing
- procedural graph systems are great for repeatability but can be hard to inspect and repair manually

## Main Representation Families

### 1. Boundary Representation (B-rep)

B-rep is the dominant representation in mechanical CAD. A solid is defined by its boundary: faces, edges, and vertices, plus the topology connecting them.

Typical geometry inside a B-rep:

- planes
- cylinders
- cones
- spheres
- torii
- NURBS surfaces
- trimmed parametric surfaces

Why it dominates engineering CAD:

- supports precise dimensions and tolerances
- enables feature modeling operations such as booleans, fillets, shelling, offsets, and chamfers
- maps well to drafting, CAM, CAE, and model-based definition workflows

Weaknesses:

- topological bookkeeping is complicated
- edits can be brittle, especially after history changes
- geometric kernels are hard to implement and expensive to maintain
- interchange across kernels can be lossy or flaky even with STEP

Useful official primer:

- Spatial glossary on B-rep: <https://www.spatial.com/glossary/b-rep>

### 2. NURBS and Spline-Based Surfaces

NURBS are one of the canonical mathematical surface representations in CAD. They are especially important for freeform surfacing while retaining exactness for many analytic forms.

Why they matter:

- standard representation for high-quality curves and surfaces
- support precision workflows better than polygon meshes
- deeply embedded in CAD, surfacing, and industrial design tools

Weaknesses:

- trimming and topology management add complexity
- direct manipulation is often less intuitive than sculpting polygonal models
- robust booleans and offsets remain hard in practice

Canonical reference:

- Piegl and Tiller, *The NURBS Book*: <https://link.springer.com/book/10.1007/978-3-642-59223-2>

### 3. Constructive Solid Geometry (CSG)

CSG represents solids as trees of boolean operations over primitives or derived solids.

Why it matters:

- compact and highly programmable
- easy to version as text
- natural fit for code-based CAD systems

Weaknesses:

- not always easy to convert back to editable face-level geometry
- local edits are awkward compared with feature-history B-rep systems
- complex real-world parts often outgrow pure primitive-tree workflows

Classic perspective:

- old but still clarifying paper on deriving CSG from drawings: <https://www.sciencedirect.com/science/article/pii/0010448586903258>

Recent survey:

- conversion from unstructured geometry to CSG: <https://www.sciencedirect.com/science/article/pii/S0010448523001872>

### 4. Polygon Meshes

Meshes dominate DCC, games, real-time rendering, sculpting, and many exchange formats.

Why they matter:

- simple, ubiquitous, easy to render
- natural for sculpting and visual content creation
- broad tool and hardware support

Weaknesses:

- approximation rather than exact geometry
- poor fit for exact dimensions and many manufacturing workflows
- operations like fillets, offsets, or robust booleans are less natural than in CAD kernels

Mesh editing and representation are their own mature literature:

- survey on mesh representation schemes: <https://researchwith.njit.edu/en/publications/whats-in-a-mesh-a-survey-of-3d-mesh-representation-schemes/>

### 5. Implicit Fields and Signed Distance Functions

Implicit modeling defines geometry as the level set of a field rather than explicit faces or triangles.

Why it matters:

- robust for lattices, blends, topology optimization, and field-driven design
- can avoid many failure modes of explicit B-rep operations
- especially attractive in additive manufacturing

Weaknesses:

- harder to inspect with traditional CAD intuition
- often needs downstream conversion to mesh or B-rep for other tools
- interoperability remains a real bottleneck

Useful practitioner primers:

- nTop on B-reps vs implicits: <https://www.ntop.com/blog/understanding-the-basics-of-b-reps-and-implicits/>
- nTop on implicit modeling for engineering design: <https://www.ntop.com/blog/implicit-modeling-for-mechanical-design/>

### 6. Procedural and Graph-Based Representations

Procedural systems define geometry through rules, node graphs, or parameterized code rather than direct manual manipulation.

Examples:

- Grasshopper graphs
- Houdini SOP networks
- Blender Geometry Nodes
- code-CAD systems like OpenSCAD and CadQuery

Why they matter:

- reproducibility
- automation
- design-space exploration
- compact parameterized definitions

Weaknesses:

- debugging graphs can be difficult
- local manual edits can fight the procedural source of truth
- procedural definitions are not always portable between systems

## Editing Paradigms

### History-Based Parametric CAD

This is the standard mechanical CAD paradigm. Users build sketches, constraints, and features in a timeline.

Strengths:

- edits are dimension-driven
- manufacturing intent can be captured explicitly
- good fit for iterative engineering changes

Weaknesses:

- history trees can become fragile
- topological naming issues can invalidate downstream references
- conceptual freeform work can feel constrained

### Direct Modeling

Direct modeling manipulates faces and features without requiring a fully explicit feature history.

Strengths:

- easier imported-geometry edits
- often faster for late-stage changes

Weaknesses:

- can lose design intent
- not always ideal for heavily parameterized families of parts

### Procedural / Algorithmic Modeling

This is best for repeatability, families of designs, generative variation, and systems design.

Strengths:

- programmable
- scalable
- automation-friendly

Weaknesses:

- less discoverable for non-programmers
- hard to debug visually once graphs or scripts become large

### Sculpting / Artistic Editing

Polygonal and subdivision workflows prioritize shape exploration and local surface feel over exact engineering precision.

Strengths:

- intuitive local shape editing
- strong for character, entertainment, and concept design

Weaknesses:

- weak for exact tolerances and downstream engineering

## Software Landscape

### Mechanical CAD

- SolidWorks, NX, Creo, CATIA, Fusion, Onshape, FreeCAD
- mostly B-rep and history-driven
- strongest for manufacturing-oriented parts and assemblies

### Surfacing / Industrial Design

- Rhino, Alias, Fusion Form environment, Plasticity
- emphasize NURBS, patch layout, and freeform surface quality

### DCC / Content Creation

- Blender, Maya, 3ds Max, Cinema 4D
- mesh-first, subdivision-friendly, artist-oriented

### Procedural Design

- Houdini, Grasshopper, Blender Geometry Nodes
- graph-based and automation-oriented

### Code-CAD

- OpenSCAD, CadQuery, Build123d, Replicad
- attractive to developers and hardware hackers

### Implicit / Field-Driven Engineering

- nTop and adjacent AM tooling
- optimized for lattices, metamaterials, and analysis-driven geometry

## Key Tensions Across Tools

### Precision vs flexibility

B-rep and NURBS systems favor exactness. Mesh and sculpt tools favor manipulation speed.

### Robustness vs expressiveness

Implicit systems often make certain operations more robust, but can be less transparent and less interoperable.

### Text or graph vs GUI

Code-CAD and node graphs excel at repeatability and version control. Traditional GUI CAD is often more accessible for local design edits.

### Native representation vs exchange

STEP, IGES, STL, OBJ, Parasolid, USD, and other formats are bridges, but every bridge leaks. Translation is still one of the chronic pain points in 3D workflows.

## Current Research Directions

### 1. B-rep-native generative models

Recent CAD research increasingly tries to generate or reconstruct B-reps directly rather than stopping at voxels or meshes.

Representative papers:

- ComplexGen: <https://huggingface.co/papers/2205.14573>
- SolidGen: <https://www.research.autodesk.com/publications/solidgen/>
- BrepGen: <https://www.research.autodesk.com/publications/brepgen/>
- CADCL: <https://academic.oup.com/jcde/article/12/10/176/8272673>

This matters because mesh-only generation is often insufficient for engineering use.

### 2. CAD reconstruction from unstructured geometry

There is active work on turning point clouds, meshes, or images into editable CAD structures.

This is difficult because the problem is not just recovering shape; it is recovering design intent, topology, and sometimes feature history.

### 3. Procedural and neurosymbolic CAD

Research on CSG induction, program synthesis, and CAD sequence generation is effectively trying to recover editable programs rather than just static shapes.

This is one of the most important long-term directions if the goal is not only to view geometry, but to edit it in semantically meaningful ways.

### 4. Implicit interoperability

The additive manufacturing ecosystem is pushing for better handoff of implicit geometry without exploding into enormous meshes.

This is less glamorous than generative AI, but probably more important in near-term industrial workflows.

## Practical Takeaways

If the goal is manufacturing-grade editing:

- B-rep systems remain the center of gravity

If the goal is hard-surface concepting or industrial design:

- NURBS and hybrid surfacing tools are often best

If the goal is procedural variation:

- graph-based or code-based systems are attractive

If the goal is lattices, topology optimization, or field-driven geometry:

- implicit systems have real structural advantages

If the goal is asset creation for rendering or games:

- mesh-first systems remain dominant

No single package wins across all of these.

## Annotated Bibliography

Notes:

- Publication dates are given as listed on the official or indexed source used here.
- "Relevance" is a subjective 1-5 score for this note.
- "Impact signal" is approximate and heterogeneous: citations for academic references, GitHub stars for open-source projects, and HN points/comments for discussion threads.

### The NURBS Book

- Date: 1995 first edition; 1997 second edition
- Authors / affiliations: Les Piegl and Wayne Tiller
- Type: textbook
- Relevance: 5/5
- Impact signal: Springer lists about 3,338 citations for the listed edition
- Why it matters: still one of the canonical references for spline and NURBS-based geometric modeling
- Sources: <https://link.springer.com/book/10.1007/978-3-642-59223-2>

### What's in a mesh? A survey of 3D mesh representation schemes

- Date: 2005
- Authors / affiliations: Craig Gotsman; New Jersey Institute of Technology listing
- Type: academic survey
- Relevance: 4/5
- Impact signal: no clean citation metric surfaced in the source snippet I used
- Why it matters: a useful classical reference for how mesh representations support editing, animation, and morphing
- Sources: <https://researchwith.njit.edu/en/publications/whats-in-a-mesh-a-survey-of-3d-mesh-representation-schemes/>

### Open CASCADE Technology

- Date: project dates back to 1999; documentation source opened was for OCCT 7.0 docs
- Authors / affiliations: Open Cascade
- Type: kernel / platform documentation
- Relevance: 5/5
- Impact signal: infrastructure importance is higher than any single visible metric; no reliable star count surfaced in the official source used
- Why it matters: the main open-source B-rep kernel in practical CAD workflows; foundational for FreeCAD, CadQuery, and many adjacent systems
- Sources: <https://dev.opencascade.org/doc/occt-7.0.0/overview/html/>, <https://old.opencascade.com/doc/occt-6.9.1/overview/html/technical_overview.html>

### Parasolid

- Date: originally 1986; current product still active
- Authors / affiliations: Siemens Digital Industries Software
- Type: kernel overview
- Relevance: 5/5
- Impact signal: no single public metric is especially meaningful; industrial adoption is the real signal
- Why it matters: the dominant commercial geometric kernel behind a large share of modern CAD products
- Sources: <https://www.spatial.com/glossary/parasolid>

### What Is B-Rep

- Date: current glossary page, crawled 2026
- Authors / affiliations: Spatial Corp
- Type: official glossary / explainer
- Relevance: 5/5
- Impact signal: not applicable
- Why it matters: concise and accurate practical description of why B-rep is central to engineering CAD
- Sources: <https://www.spatial.com/glossary/b-rep>

### A Survey of Methods for Converting Unstructured Data to CSG Models

- Date: March 2024
- Authors / affiliations: published in *Computer-Aided Design*
- Type: academic survey
- Relevance: 4/5
- Impact signal: no citation count surfaced in the source snippet I used
- Why it matters: good overview of the program-synthesis and reverse-engineering line from meshes and point clouds into editable CSG
- Sources: <https://www.sciencedirect.com/science/article/pii/S0010448523001872>

### ComplexGen: CAD Reconstruction by B-Rep Chain Complex Generation

- Date: May 29, 2022
- Authors / affiliations: Haoxiang Guo, Shilin Liu, Hao Pan, Yang Liu, Xin Tong, Baining Guo
- Type: academic paper
- Relevance: 5/5
- Impact signal: no reliable citation metric surfaced in the source snippet I used
- Why it matters: one of the more concrete examples of treating CAD reconstruction as structured B-rep recovery rather than generic shape generation
- Sources: <https://huggingface.co/papers/2205.14573>

### SolidGen: An Autoregressive Model for Direct B-rep Synthesis

- Date: 2023 on Autodesk Research page, with associated publication trail from 2022 onward
- Authors / affiliations: Autodesk Research with collaborators including University of Toronto / Vector Institute
- Type: academic paper
- Relevance: 5/5
- Impact signal: no reliable citation count surfaced in the source snippet I used
- Why it matters: strong sign that direct B-rep generation is becoming a first-class research target
- Sources: <https://www.research.autodesk.com/publications/solidgen/>

### BrepGen: A B-rep Generative Diffusion Model with Structured Latent Geometry

- Date: 2024
- Authors / affiliations: Autodesk Research
- Type: academic paper
- Relevance: 5/5
- Impact signal: no reliable citation count surfaced in the source snippet I used
- Why it matters: notable because it pushes generative modeling toward watertight B-rep solids rather than only visual geometry
- Sources: <https://www.research.autodesk.com/publications/brepgen/>

### CADCL: Reconstruct parametric CAD models from B-rep via contrastive learning

- Date: October 3, 2025
- Authors / affiliations: Wuhan University and Shenzhen Polytechnic University
- Type: academic paper
- Relevance: 4/5
- Impact signal: too recent for a meaningful citation count in the sources I checked
- Why it matters: a good example of the next step after shape recovery: reconstructing parametric CAD sequences from B-rep data
- Sources: <https://academic.oup.com/jcde/article/12/10/176/8272673>

### Grasshopper

- Date: active software page, crawled 2026
- Authors / affiliations: McNeel / Grasshopper community
- Type: official software overview
- Relevance: 4/5
- Impact signal: community size on the official site, including major plugin ecosystems
- Why it matters: still one of the defining procedural and parametric graph systems in design practice
- Sources: <https://www.grasshopper3d.com/>, <https://www.grasshopper3d.com/main/>

### Geometry Nodes

- Date: Blender manual pages current through 2025 documentation snapshots
- Authors / affiliations: Blender project
- Type: official software documentation
- Relevance: 4/5
- Impact signal: no single metric used here; practical adoption across Blender workflows is the relevant signal
- Why it matters: Blender’s node system is one of the clearest examples of procedural geometry moving into mainstream open-source 3D editing
- Sources: <https://docs.blender.org/manual/en/latest/modeling/geometry_nodes/index.html>, <https://docs.blender.org/manual/en/latest/modeling/geometry_nodes/geometry/index.html>

### FreeCAD

- Date: software project active; GitHub snapshot crawled 2026
- Authors / affiliations: FreeCAD project
- Type: open-source software
- Relevance: 5/5
- Impact signal: about 27.9k GitHub stars; HN thread on FreeCAD 1.0 had 28 points
- Why it matters: the main open-source parametric CAD platform, and the clearest real-world showcase of OCCT-based open engineering CAD
- HN cross-reference: the useful HN discussion centers on the topological naming problem, kernel limitations, and the gap between being capable and being pleasant
- Sources: <https://github.com/FreeCAD/FreeCAD>, <https://news.ycombinator.com/item?id=42185729>, <https://news.ycombinator.com/item?id=41515101>, <https://news.ycombinator.com/item?id=42431386>

### OpenSCAD

- Date: software originally released 2010; current repo snapshot crawled 2026
- Authors / affiliations: OpenSCAD project
- Type: open-source software
- Relevance: 5/5
- Impact signal: about 8.7k GitHub stars; major HN thread had 475 points and 187 comments
- Why it matters: the archetypal code-CAD / CSG system. It is less capable than full B-rep CAD, but hugely important as a programmable modeling paradigm
- HN cross-reference: HN discussions are especially useful here because they articulate the exact tradeoff: superb versionability and parametric programmability, but weak constraint solving, weak face-level edits, and limited manufacturing-grade operations
- Sources: <https://github.com/openscad/openscad>, <https://news.ycombinator.com/item?id=41543386>, <https://news.ycombinator.com/item?id=24514978>, <https://news.ycombinator.com/item?id=27517503>

### CadQuery

- Date: active project; GitHub snapshot crawled 2026
- Authors / affiliations: CadQuery project
- Type: open-source software
- Relevance: 5/5
- Impact signal: about 4.2k GitHub stars; HN threads reached 104 and 134 points
- Why it matters: probably the clearest modern code-CAD alternative to OpenSCAD for users who want Python, OCCT, STEP, and stronger CAD semantics
- HN cross-reference: HN comments repeatedly position CadQuery as the "developer-friendly" bridge between scriptability and real CAD capability
- Sources: <https://github.com/CadQuery/cadquery>, <https://github.com/CadQuery>, <https://news.ycombinator.com/item?id=30232344>, <https://news.ycombinator.com/item?id=24520014>

### Onshape

- Date: current platform pages and 2026 MBD announcement
- Authors / affiliations: PTC / Onshape
- Type: commercial cloud CAD platform
- Relevance: 4/5
- Impact signal: HN discussion of "A New Era for Mechanical CAD" reached 126 points and 107 comments
- Why it matters: a strong representative of cloud-native CAD, collaborative versioned modeling, and the argument that CAD should behave more like modern software tooling
- HN cross-reference: the HN article discussion is valuable because it surfaces the deeper issues around kernels, versioning, PDM, and enterprise switching costs
- Sources: <https://www.onshape.com/en/platform>, <https://www.ptc.com/en/news/2026/ptc-launches-onshape-mbd-capabilites>, <https://www.onshape.com/en/resource-center/tech-tips/import-edit-step-iges-parasolid-stl>, <https://www.onshape.com/en/resource-center/tech-tips/import-file-formats-step-parasolid-stl-dxf-dwg-pdf>, <https://news.ycombinator.com/item?id=27517503>

### nTop and Implicit Modeling

- Date: core blog references from 2019 onward; kernel update docs in 2024
- Authors / affiliations: nTop
- Type: software and practitioner literature
- Relevance: 5/5
- Impact signal: no single public metric used here
- Why it matters: probably the clearest modern industrial case for implicit modeling as a primary design representation, especially in additive manufacturing
- Sources: <https://www.ntop.com/blog/understanding-the-basics-of-b-reps-and-implicits/>, <https://www.ntop.com/blog/implicit-modeling-for-mechanical-design/>, <https://support.ntop.com/hc/en-us/articles/26062971882131-nTop-5-0-New-Implicit-Modeling-Kernel>, <https://support.ntop.com/hc/en-us/articles/7323109441683-nTopology-3-28-What-s-New>, <https://www.eos.info/press-media/press-center/press-releases/2023/eos-partners-with-ntopology>

### Blender

- Date: active project; GitHub mirror snapshot crawled 2026
- Authors / affiliations: Blender project
- Type: open-source DCC software
- Relevance: 4/5
- Impact signal: GitHub mirror present but stars were not surfaced in the snippet I used; HN discussions around Geometry Nodes vs Houdini are qualitative rather than canonical
- Why it matters: mesh-first editing remains the center of gravity for artistic 3D work, and Blender is the key open-source reference point
- HN cross-reference: HN comments usually frame Blender Geometry Nodes as increasingly powerful but still distinct from the deeper procedural integration that Houdini users expect
- Sources: <https://github.com/blender/blender>, <https://docs.blender.org/manual/en/latest/modeling/geometry_nodes/index.html>, <https://news.ycombinator.com/item?id=44573472>

### ShapeGraMM

- Date: November 2023
- Authors / affiliations: published in *Computers & Graphics*
- Type: academic paper
- Relevance: 3/5
- Impact signal: no reliable citation metric surfaced in the snippet I used
- Why it matters: a useful procedural-modeling reference showing that compact generative scene descriptions remain relevant beyond entertainment-only workflows
- Sources: <https://www.sciencedirect.com/science/article/pii/S0097849323001887>

### A New Era for Mechanical CAD

- Date: June 2021 HN discussion of the ACM article
- Authors / affiliations: HN thread around ACM article
- Type: discussion / industry context
- Relevance: 4/5
- Impact signal: 126 HN points and 107 comments
- Why it matters: one of the better HN discussions for understanding why CAD evolves slowly: kernel complexity, interop, enterprise lock-in, and the difference between flashy UI ideas and production engineering reality
- Sources: <https://news.ycombinator.com/item?id=27517503>

### Show HN: Open-sourcing our text-to-CAD app

- Date: 2025
- Authors / affiliations: Adam
- Type: HN / applied system
- Relevance: 3/5
- Impact signal: 179 HN points and 23 comments
- Why it matters: a useful applied example of the current state of text-to-CAD systems, which still tend to target OpenSCAD-like program generation rather than full industrial CAD semantics
- Sources: <https://news.ycombinator.com/item?id=45140921>

## Bottom Line

The most important divide in 3D software is not "CAD vs 3D modeling." It is:

1. exact editable engineering geometry
2. approximate visual geometry
3. field-based or procedural geometry

Most tools mix more than one of these, but usually one representation still dominates the editing model.

If you care about manufacturable, dimensioned parts, B-rep still rules.
If you care about visual modeling and animation, meshes still rule.
If you care about automation, lattices, or generative design at scale, implicit and procedural systems are increasingly where the real innovation is happening.
