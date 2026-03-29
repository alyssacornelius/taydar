# Scene Reconstruction Literature Review

## Scope

This note summarizes the current landscape of methods that go from 2D image input to 3D output. "3D output" can mean different things:

- a textured triangle mesh
- a point cloud or depth map
- an implicit radiance field
- a neural or explicit surface representation
- a 3D Gaussian splat representation

There are three practical problem settings:

1. Many photos of the same real object or scene -> reconstruction
2. One photo of an object -> generative reconstruction with learned priors
3. One or a few photos, where fast asset creation matters more than metric fidelity -> feed-forward image-to-3D

## Main Method Families

### 1. Classical Structure-from-Motion and Multi-View Stereo

This is still the baseline when you have many overlapping photos of a real scene or object and want accurate geometry.

- Structure-from-Motion estimates camera poses and sparse geometry
- Multi-View Stereo densifies the reconstruction
- outputs are typically sparse point clouds, dense point clouds, and meshes

Strengths:

- strong geometric fidelity when image coverage is good
- metric or near-metric reconstruction is possible
- mature tooling and well-understood failure modes

Weaknesses:

- needs multiple overlapping images
- does not work well for single-image reconstruction
- struggles with reflective, transparent, textureless, or dynamic content

Canonical system:

- COLMAP: <https://github.com/colmap/colmap>

### 2. NeRF and Neural Radiance Fields

NeRF-style methods represent a scene as a continuous volumetric field that can be rendered from novel viewpoints.

Strengths:

- excellent novel-view synthesis quality
- good handling of complex appearance and view-dependent effects
- strong research foundation for neural 3D representations

Weaknesses:

- original methods were slow to optimize
- geometry is implicit rather than directly mesh-native
- extracting clean surfaces can be awkward

Important references:

- Instant-NGP: fast training and rendering for NeRF-like fields  
  <https://docs.nerf.studio/nerfology/methods/instant_ngp.html>

### 3. Neural Implicit Surfaces and SDF-Based Reconstruction

These methods are more surface-oriented than radiance-field methods and are often a better fit when the goal is explicit geometry or meshes.

Strengths:

- stronger surface recovery than pure radiance-field methods
- cleaner mesh extraction
- good fit for reconstruction-oriented pipelines

Weaknesses:

- still typically require multiple views for reliable recovery
- training and inference can be computationally heavy

Canonical example:

- NeuS: <https://huggingface.co/papers/2106.10689>

### 4. 3D Gaussian Splatting

Gaussian splatting is now one of the major 3D representation families. It represents objects or scenes as large sets of anisotropic 3D Gaussians with color and opacity attributes, enabling high-quality real-time rendering.

Strengths:

- very fast rendering
- strong novel-view synthesis quality
- explicit representation that is easier to render in real time than many neural fields

Weaknesses:

- not a mesh-first representation
- geometry is often less directly usable for CAD, simulation, or game-engine workflows
- mesh extraction is usually a downstream conversion step, not the native representation

Core reference:

- 3D Gaussian Splatting: <https://huggingface.co/papers/2308.04079>

Review:

- Recent advances in 3D Gaussian splatting: <https://link.springer.com/article/10.1007/s41095-024-0436-y>

## Image-to-3D Literature

### Zero-1-to-3

Zero-1-to-3 was an important transition point from image generation to 3D generation. It uses viewpoint-conditioned diffusion to synthesize novel views from a single image, which can then support downstream 3D reconstruction.

Interpretation:

- more "single-image novel view synthesis" than direct mesh prediction
- foundational for later image-to-3D systems that generate multi-view imagery first

References:

- Paper: <https://huggingface.co/papers/2303.11328>
- Code: <https://github.com/cvlab-columbia/zero123>

### One-2-3-45

This system uses generated multi-view images and then reconstructs a textured 3D mesh without per-instance optimization in the style of slower SDS pipelines.

Interpretation:

- early practical image-to-mesh pipeline
- important because it framed single-image 3D as multi-view generation followed by geometric lifting

Reference:

- Paper: <https://huggingface.co/papers/2306.16928>

### LRM: Large Reconstruction Model

LRM is one of the key foundation-style single-image-to-3D papers. It predicts 3D content directly from a single image using a transformer-based reconstruction model trained on large-scale multi-view data.

Interpretation:

- major shift from optimization-heavy pipelines toward feed-forward reconstruction
- important precursor to several faster practical systems

Reference:

- Adobe Research page: <https://research.adobe.com/publication/lrm-large-reconstruction-model-for-single-image-to-3d/>

### TripoSR

TripoSR is a fast feed-forward model derived from the LRM direction. It is notable for making single-image object reconstruction much faster and more practical for interactive workflows.

Interpretation:

- strong practical open model
- useful when speed matters more than perfect geometry

References:

- Paper: <https://huggingface.co/papers/2403.02151>
- Model card: <https://huggingface.co/stabilityai/TripoSR>

### Wonder3D

Wonder3D predicts consistent multi-view RGB images and normal maps, then fuses them into textured geometry.

Interpretation:

- notable for geometry consistency
- more mesh-oriented than some radiance-first approaches

References:

- Paper: <https://huggingface.co/papers/2310.15008>
- Code: <https://github.com/xxlong0/Wonder3D>

### InstantMesh

InstantMesh is one of the stronger practical open-source image-to-mesh systems. It combines multi-view generation with sparse-view reconstruction and is oriented toward producing usable assets quickly.

Interpretation:

- good candidate when the desired output is a textured mesh
- practical tradeoff between quality and speed

References:

- Paper: <https://huggingface.co/papers/2404.07191>
- Code: <https://github.com/TencentARC/InstantMesh>

### LGM

LGM predicts 3D Gaussian representations from generated or inferred multi-view imagery.

Interpretation:

- especially relevant for image-to-3D pipelines where the target output can be splats rather than meshes
- high-quality renderable assets with optional later mesh conversion

References:

- Paper: <https://huggingface.co/papers/2402.05054>
- Code: <https://github.com/3DTopia/LGM>

### AGG

AGG is an amortized single-image-to-3D Gaussian method that avoids per-instance optimization and directly predicts 3D Gaussian content.

Interpretation:

- good example of direct image-to-splat generation
- important if the target representation is real-time renderable rather than explicitly meshed

Reference:

- OpenReview: <https://openreview.net/forum?id=BOq3n5ewSP>

### DUSt3R

DUSt3R is more reconstruction-oriented than asset-generation-oriented. It is relevant when you have multiple images of a real scene but do not want the brittleness of a full classical calibration pipeline.

Interpretation:

- more geometry and reconstruction focused
- useful for real scenes rather than just generative object assets

Reference:

- CVPR 2024 poster page: <https://cvpr.thecvf.com/virtual/2024/poster/29338>

### Hunyuan3D 2.0

Hunyuan3D 2.0 is a newer practical open system for text-to-3D and image-to-3D asset generation using separate shape and texture stages.

Interpretation:

- strong practical system for high-quality assets
- relevant for current open-source benchmarking and experimentation

Reference:

- Official GitHub: <https://github.com/Tencent-Hunyuan/Hunyuan3D-2>

### TRELLIS and TRELLIS.2

TRELLIS and TRELLIS.2 are newer large generative 3D systems from Microsoft that support image-conditioned 3D output with multiple possible representations.

Interpretation:

- useful examples of newer large-scale 3D generative systems
- relevant when comparing mesh-oriented and splat-oriented outputs

References:

- TRELLIS: <https://github.com/microsoft/TRELLIS>
- TRELLIS.2: <https://github.com/microsoft/TRELLIS.2>

## Where Gaussian Splatting Fits

Gaussian splatting absolutely belongs in the image-to-3D landscape. The main reason it can look under-emphasized in some summaries is that it is not the same thing as direct image-to-mesh reconstruction.

The cleanest taxonomy is:

1. Image(s) -> mesh or surface
2. Image(s) -> radiance field or NeRF
3. Image(s) -> Gaussian splats

Gaussian splatting should be treated as a first-class 3D output type.

It is especially strong for:

- real-time rendering
- novel-view synthesis
- practical visual scene capture
- object or scene representations where visual plausibility matters more than watertight surfaces

It is weaker when the downstream task specifically requires:

- editable clean meshes
- CAD-style geometry
- robust physical simulation
- asset pipelines that need topology-aware editing

So the answer to "does Gaussian splatting fit into 2D-to-3D?" is yes. The answer to "is it equivalent to image-to-mesh?" is no.

## Practical Summary

If the goal is accurate real-world geometry from many photos:

- use COLMAP-style reconstruction or geometry-oriented learned methods such as DUSt3R

If the goal is best-in-class novel-view realism:

- use NeRF-style methods or 3D Gaussian Splatting

If the goal is fast single-image asset generation:

- use TripoSR, InstantMesh, Wonder3D, Hunyuan3D 2.0, or TRELLIS-family systems depending on desired output type

If the goal is a renderable real-time 3D representation rather than a mesh:

- Gaussian-based methods such as LGM or AGG are directly relevant

## Important Caveat

Single-image 3D methods are strongly prior-driven. When only one view is given, any method must infer hidden geometry, including the back side of the object or scene. That means these systems often produce plausible geometry rather than ground-truth geometry.

For applications needing metric accuracy, multi-view pipelines remain substantially more reliable than single-image generative pipelines.

## What Could Run On iPhone

This section is about deployment on iPhone-class hardware, not just academic quality. There are three very different questions hidden inside "can it run on iPhone?":

1. Can the model be viewed or rendered on iPhone after offline reconstruction?
2. Can the model perform inference on-device on iPhone?
3. Can the full reconstruction or training loop happen on-device on iPhone?

Those are very different bars. Rendering is easiest. Feed-forward inference is harder. Full optimization or training on-device is the hardest.

### iPhone Deployment Buckets

#### A. Already practical on iPhone today

These are either officially supported on iOS or already demonstrated in production iPhone apps.

##### 1. Apple Object Capture on iOS

Apple documents `PhotogrammetrySession` for creating 3D objects from photographs on iOS 17+ and macOS 12+, with availability limited to select iOS devices with LiDAR capabilities.

Implication:

- this is the strongest official signal that a mesh-oriented multi-image reconstruction pipeline is viable natively on iPhone
- it is not a single-image generative model; it is a photogrammetry pipeline using many images
- if the product goal is "capture a real object on phone and get a 3D model," this is the most native Apple-aligned path

References:

- Apple docs: <https://developer.apple.com/documentation/realitykit/creating-3d-objects-from-photographs/>
- Apple WWDC session: <https://www.youtube.com/watch?v=zrSlmedQfq0&vl=en>

Practical iPhone suitability: 5/5

##### 2. On-device Gaussian Splatting capture in Scaniverse

Scaniverse states that 3D Gaussian splat capture and training can happen entirely on-device, with no cloud requirement unless the user chooses to share the result. Their support pages say the app runs on many iPhones, while splat capture specifically requires newer devices, with iPhones 12 or newer listed for splat capture in the current support docs.

Implication:

- this is the clearest real-world proof that iPhone-class hardware can support an end-to-end splat pipeline for scene capture
- it does not imply that arbitrary research splat-training code will run efficiently in an app, but it does prove the class of approach is viable
- splats are especially attractive on mobile because the output is renderable without requiring a clean mesh

References:

- Scaniverse splats announcement: <https://scaniverse.com/news/scaniverse-introduces-support-for-3d-gaussian-splatting>
- Scaniverse device support: <https://scaniverse.com/support>
- SPZ format and mobile motivation: <https://scaniverse.com/spz>

Practical iPhone suitability: 5/5

##### 3. Viewing precomputed Gaussian splats on iPhone

Viewing is much easier than training. Several Apple-platform products and viewers already support splat viewing on iPhone or across Apple platforms.

Implication:

- if reconstruction happens off-device, splat viewing on iPhone is already practical
- mobile viability depends strongly on compression, level of detail, and scene size

Reference:

- Spatial Fields viewer: <https://spatialfields.app/>

Practical iPhone suitability: 5/5 for viewing, 2/5 for training generic research models

#### B. Feasible on iPhone with conversion or model reduction

These methods are not primarily iPhone-native, but their inference path is small or structured enough that a carefully engineered port could be realistic.

##### 4. TripoSR-style feed-forward reconstruction models

TripoSR is one of the more realistic image-to-3D candidates for iPhone deployment because it is feed-forward and optimized for fast inference rather than long per-instance optimization.

Why it is plausible:

- no heavy score-distillation optimization loop
- single-image object reconstruction rather than whole-scene training
- the model is already framed as fast practical inference

Why it is still hard:

- the original release targets desktop-class PyTorch workflows
- memory pressure, operator compatibility, and latency on iPhone are still nontrivial
- mesh extraction and postprocessing may need a hybrid CPU/GPU path

Assessment:

- feasible as a reduced or distilled variant
- less realistic as a direct unmodified port of the reference implementation

Practical iPhone suitability: 3/5

##### 5. MobileNeRF-style representations

MobileNeRF was explicitly designed to make neural field rendering efficient on mobile architectures by moving the representation toward polygon rasterization and lightweight shading.

Implication:

- this is one of the clearest examples of a neural 3D representation designed with mobile deployment in mind
- it is more relevant for rendering precomputed representations than for full on-device reconstruction
- conceptually, it fits iPhone graphics hardware better than classic volumetric NeRF rendering

References:

- Paper: <https://huggingface.co/papers/2208.00277>
- Citation snapshot: <https://liner.com/review/mobilenerf-exploiting-polygon-rasterization-pipeline-for-efficient-neural-field-rendering>

Practical iPhone suitability: 4/5 for rendering, 2/5 for reconstruction

##### 6. MobileR2L and similar mobile neural rendering systems

Snap's MobileR2L is another signal that real-time neural rendering on mobile devices is feasible when the representation is explicitly engineered for that hardware regime.

Implication:

- relevant for mobile scene rendering and playback
- less directly relevant for single-image mesh generation
- useful as a design reference if the product needs on-device viewing of learned scenes rather than native mesh extraction

Reference:

- Official repo: <https://github.com/snap-research/MobileR2L>

Practical iPhone suitability: 4/5 for playback, 1/5 for full reconstruction

#### C. Technically portable to iOS, but unlikely to be practical unmodified

These models are often convertable in principle, but the original systems are too large, too memory-hungry, or too dependent on desktop-class inference stacks to be good first choices for iPhone deployment.

##### 7. InstantMesh, Wonder3D, LRM, LGM, Hunyuan3D 2.0, TRELLIS.2

Most recent image-to-3D research systems fall into this bucket.

Why they are technically possible:

- Apple supports direct PyTorch-to-Core ML conversion through `coremltools`
- Core ML can run converted models across CPU, GPU, and Neural Engine
- model compression techniques such as quantization and palettization exist within the Apple deployment stack

Why they are usually poor first iPhone targets:

- many use large diffusion or transformer components
- intermediate tensors and multi-view generation stages can be expensive in memory
- some depend on custom ops or Python-centric postprocessing that do not map cleanly into a native app
- even when one network converts, the full pipeline may still be impractical

References:

- Apple Core ML Tools conversion docs: <https://apple.github.io/coremltools/docs-guides/source/convert-pytorch.html>
- Apple PyTorch conversion workflow: <https://apple.github.io/coremltools/docs-guides/source/convert-pytorch-workflow.html>
- Hugging Face Core ML diffusion guide: <https://huggingface.co/docs/diffusers/optimization/coreml>

Practical iPhone suitability:

- LRM: 2/5
- Wonder3D: 2/5
- InstantMesh: 2/5
- LGM: 2/5
- Hunyuan3D 2.0: 1/5
- TRELLIS.2: 1/5

### Core ML and Native iOS Inference Constraints

Apple's official tooling makes conversion possible, but "convertable" is not the same as "product-viable."

What works in favor of iPhone deployment:

- direct PyTorch-to-Core ML conversion is supported by Apple
- Core ML can target CPU, GPU, and Apple Neural Engine
- quantization and weight compression can materially reduce footprint

What usually blocks research pipelines:

- unsupported or awkward operators
- large diffusion backbones
- multi-stage pipelines that allocate large intermediate activations
- postprocessing outside the model graph
- scene-scale memory demands for splats or radiance fields

In practice, the best iPhone candidates usually have at least one of these properties:

- feed-forward rather than optimization-based
- object-scale rather than room-scale generation
- rendering-first rather than mesh-first output
- compressed or distilled backbone
- explicit mobile-oriented representation

### Bottom Line For iPhone

If the goal is an iPhone-native app today:

- best mesh-oriented path: Apple Object Capture on supported LiDAR devices
- best splat-oriented path: an on-device capture workflow in the style of Scaniverse
- best research direction for native rendering: MobileNeRF-style or mobile-optimized neural rendering
- best candidate among modern image-to-3D generators for eventual on-device inference: a reduced TripoSR-style feed-forward model

If the goal is to ship something soon, the most realistic architecture is usually:

1. Capture on iPhone
2. Do either lightweight on-device reconstruction or server-side heavy reconstruction
3. Return a mobile-friendly representation such as USDZ mesh or compressed splats for viewing

For fully on-device generation from a single 2D image, current large image-to-3D research models are mostly still too heavy to recommend as-is for iPhone deployment.

## Useful Survey

- Advances in 3D Generation: A Survey  
  <https://huggingface.co/papers/2401.17807>

## Annotated Bibliography

Notes:

- Publication dates and affiliations are taken from the project pages, paper pages, or official repositories linked below.
- "Relevance" is a subjective 1-5 score for this note's focus on image-to-3D and scene reconstruction. 5 means directly central.
- "Impact signal" is intentionally mixed. I use citation counts where an indexing source exposed them in search results, and GitHub stars where code adoption is the more meaningful proxy.
- All impact signals below are approximate snapshots as of 2026-03-29.

### COLMAP

- Date: 2016 for the core SfM and MVS papers; actively maintained software through 2026
- Authors / affiliations: Johannes L. Schonberger, Jan-Michael Frahm, Marc Pollefeys and collaborators; software credits cite ETH Zurich and UNC Chapel Hill
- Relevance: 5/5
- Impact signal: about 10.6k GitHub stars
- Why it matters: still the default classical baseline for multi-view geometry when the goal is accurate reconstruction from many photos rather than learned single-image hallucination
- Sources: <https://github.com/colmap/colmap>, <https://colmap.github.io/>

### Instant-NGP

- Date: July 2022
- Authors / affiliations: Thomas Muller, Alex Evans, Christoph Schied, Alexander Keller; NVIDIA / NVLabs
- Relevance: 4/5
- Impact signal: about 17.2k GitHub stars
- Why it matters: made NeRF-style optimization dramatically faster and helped turn neural field reconstruction from a research curiosity into a practical baseline
- Sources: <https://github.com/NVlabs/instant-ngp>

### NeuS

- Date: June 20, 2021 preprint; NeurIPS 2021
- Authors / affiliations: University of Hong Kong, MPI Informatics at Saarland Informatics Campus, and Texas A&M University
- Relevance: 4/5
- Impact signal: about 992 Scopus citations, plus about 1.8k GitHub stars for the official code
- Why it matters: a canonical neural implicit surface method when the output needs to be a surface or mesh rather than only a renderable radiance field
- Sources: <https://lingjie0206.github.io/papers/NeuS/index.htm>, <https://researchportal.hkust.edu.hk/en/publications/neus-learning-neural-implicit-surfaces-by-volume-rendering-for-mu-2/>, <https://github.com/Totoro97/NeuS>

### 3D Gaussian Splatting for Real-Time Radiance Field Rendering

- Date: July 2023 in ACM Transactions on Graphics / SIGGRAPH 2023; arXiv August 2023
- Authors / affiliations: Inria, Universite Cote d'Azur, and MPI Informatik
- Relevance: 5/5
- Impact signal: about 21.2k GitHub stars for the reference implementation
- Why it matters: the defining paper for Gaussian splatting as a first-class 3D representation family for real-time novel-view rendering
- HN cross-reference: the strongest discussion I found was not the paper thread itself but engineering-heavy follow-on discussions around browser rendering and the implications for dynamic lighting, game engines, and scene compositing. Those threads reinforce the key practical limitation of splats: they are excellent for static captured scenes, but less natural than meshes for interactive game worlds and editable geometry.
- Sources: <https://repo-sam.inria.fr/fungraph/3d-gaussian-splatting/>, <https://github.com/graphdeco-inria/gaussian-splatting>, <https://huggingface.co/papers/2308.04079>, <https://news.ycombinator.com/item?id=37470611>, <https://news.ycombinator.com/item?id=37518401>

### Zero-1-to-3

- Date: March 20, 2023
- Authors / affiliations: Columbia University and Toyota Research Institute
- Relevance: 5/5
- Impact signal: about 1,256 citations from the citation index shown in Liner, plus about 3k GitHub stars
- Why it matters: one of the pivotal papers that reframed single-image 3D as viewpoint-conditioned image generation followed by downstream 3D lifting
- HN cross-reference: the HN thread is unusually good and lines up with the main caveat from the paper literature. Commenters immediately focused on back-side hallucination, the difference between "plausible 3D" and recoverable geometry, and the fact that this is far more useful for generative asset iteration than for faithful scanning of a real object.
- Sources: <https://github.com/cvlab-columbia/zero123>, <https://liner.com/review/zero1to3-zeroshot-one-image-to-3d-object>, <https://news.ycombinator.com/item?id=35242193>

### One-2-3-45

- Date: June 29, 2023 preprint; published in NeurIPS 2024 proceedings
- Authors / affiliations: UC San Diego, UCLA, Cornell University, Zhejiang University, IIT Madras, and Adobe Research
- Relevance: 5/5
- Impact signal: about 518 citations from the citation index shown in Liner
- Why it matters: an early and influential "generate multi-view images, then reconstruct geometry" pipeline for fast single-image textured mesh generation
- Sources: <https://one-2-3-45.github.io/>, <https://liner.com/review/one2345-any-single-image-to-3d-mesh-in-45-seconds>

### LRM: Large Reconstruction Model for Single Image to 3D

- Date: November 8, 2023 preprint; ICLR 2024 oral; Adobe Research page lists May 7, 2024 publication date
- Authors / affiliations: primarily Adobe Research, with Yicong Hong also listed at the Australian National University
- Relevance: 5/5
- Impact signal: about 1.22k GitHub-linked adoption signal from the Hugging Face paper page; direct citation count was not surfaced in the sources I checked
- Why it matters: one of the clearest shifts from optimization-heavy single-image 3D pipelines to foundation-style feed-forward reconstruction
- Sources: <https://yiconghong.me/LRM/>, <https://research.adobe.com/publication/lrm-large-reconstruction-model-for-single-image-to-3d/>, <https://huggingface.co/papers/2311.04400>

### TripoSR

- Date: March 4, 2024
- Authors / affiliations: developed collaboratively by Tripo AI / VAST AI Research and Stability AI
- Relevance: 5/5
- Impact signal: about 6.3k GitHub stars
- Why it matters: a practical open feed-forward image-to-3D model that pushed inference latency into the sub-second range
- HN cross-reference: I did not find a meaningful HN discussion thread for the paper or official release itself.
- Sources: <https://github.com/VAST-AI-Research/TripoSR>, <https://huggingface.co/stabilityai/TripoSR>

### Wonder3D

- Date: October 23, 2023 preprint; CVPR 2024 Highlight
- Authors / affiliations: The University of Hong Kong, Tsinghua University, VAST, University of Pennsylvania, ShanghaiTech University, MPI Informatik, and Texas A&M University
- Relevance: 5/5
- Impact signal: about 179 Scopus citations, plus about 5.3k GitHub stars
- Why it matters: an important mesh-oriented image-to-3D method that explicitly predicts consistent multi-view RGB and normals before fusion
- Sources: <https://www.xxlong.site/Wonder3D/>, <https://researchportal.hkust.edu.hk/en/publications/wonder3d-single-image-to-3d-using-cross-domain-diffusion-2>, <https://github.com/xxlong0/Wonder3D>

### InstantMesh

- Date: April 10, 2024
- Authors / affiliations: Jiale Xu, Weihao Cheng, Yiming Gao, Xintao Wang, Shenghua Gao, Ying Shan; official code released by Tencent ARC
- Relevance: 5/5
- Impact signal: about 4.3k GitHub stars
- Why it matters: one of the strongest practical open single-image-to-mesh systems for fast asset creation
- Sources: <https://github.com/TencentARC/InstantMesh>, <https://huggingface.co/TencentARC/InstantMesh>, <https://github.com/tencentarc>

### LGM: Large Multi-View Gaussian Model for High-Resolution 3D Content Creation

- Date: February 7, 2024 preprint; ECCV 2024 oral
- Authors / affiliations: Peking University, S-Lab at Nanyang Technological University, and Shanghai AI Lab
- Relevance: 5/5
- Impact signal: about 2.1k GitHub stars
- Why it matters: one of the clearest image-to-Gaussian-splats systems, and central if the target output is a splat representation instead of a mesh
- Sources: <https://me.kiui.moe/lgm/>, <https://github.com/3DTopia/LGM>, <https://huggingface.co/papers/2402.05054>

### DUSt3R

- Date: December 21, 2023 preprint; CVPR 2024
- Authors / affiliations: Naver Labs Europe / Naver Corporation
- Relevance: 5/5
- Impact signal: about 7k GitHub stars
- Why it matters: especially relevant for scene reconstruction from multiple unposed images, where it relaxes the dependence on a classical camera-calibration-first pipeline
- HN cross-reference: the HN thread is useful because it captures both the enthusiasm and the central criticism. Commenters highlighted compelling "few casual photos of a room" use cases, but they also repeatedly noted that DUSt3R relies heavily on learned priors and may hallucinate geometry when overlap is weak or absent. That is exactly the right way to position the method.
- Sources: <https://europe.naverlabs.com/research/publications-enhanced/dust3r-geometric-3d-vision-made-easy/>, <https://github.com/naver/dust3r>, <https://huggingface.co/papers/2312.14132>, <https://news.ycombinator.com/item?id=39581047>

### AGG: Amortized Generative 3D Gaussians for Single Image to 3D

- Date: January 8, 2024 preprint; accepted by TMLR and listed by NVIDIA Research in October 2024
- Authors / affiliations: NVIDIA Research-led collaboration; the NVIDIA project pages list the authors but do not enumerate every institution in the snippet I reviewed
- Relevance: 4/5
- Impact signal: no robust citation count surfaced in the sources I used; I am treating this as a lower-visibility but technically important paper
- Why it matters: a direct single-image-to-Gaussian method that avoids per-instance optimization and helps define the amortized splat-generation direction
- Sources: <https://research.nvidia.com/labs/genair/publication/xu2024agg/>, <https://openreview.net/forum?id=BOq3n5ewSP>, <https://huggingface.co/papers/2401.04099>

### Hunyuan3D 2.0

- Date: January 2025 technical report and open release cycle
- Authors / affiliations: Tencent Hunyuan3D Team / Tencent
- Relevance: 4/5
- Impact signal: about 13.4k GitHub stars
- Why it matters: a current strong open system for image-conditioned and text-conditioned textured 3D asset generation, with a two-stage shape plus texture pipeline
- Sources: <https://github.com/Tencent-Hunyuan/Hunyuan3D-2>

### TRELLIS.2

- Date: 2025 technical report and code release
- Authors / affiliations: Tsinghua University, Microsoft Research, Microsoft AI, and USTC
- Relevance: 4/5
- Impact signal: about 4.6k GitHub stars
- Why it matters: a recent large image-to-3D model that emphasizes native 3D latents, high fidelity, arbitrary topology, and richer material output
- Sources: <https://microsoft.github.io/TRELLIS.2/>, <https://github.com/microsoft/TRELLIS.2>

### Recent advances in 3D Gaussian splatting

- Date: July 8, 2024
- Authors / affiliations: Institute of Computing Technology at the Chinese Academy of Sciences, Tencent AI Lab, VAST, and UC Santa Barbara
- Relevance: 4/5
- Impact signal: the article page reports about 24k accesses; I did not find a reliable citation count in the sources I used
- Why it matters: a useful review article for orienting within the rapidly expanding Gaussian-splatting literature after the original 3DGS paper
- Sources: <https://link.springer.com/article/10.1007/s41095-024-0436-y>, <https://www.sciopen.com/article/10.1007/s41095-024-0436-y>

### Advances in 3D Generation: A Survey

- Date: January 31, 2024 preprint
- Authors / affiliations: not enumerated in the source snippets I used for this note
- Relevance: 3/5
- Impact signal: no reliable citation or adoption metric surfaced in the sources I used
- Why it matters: broad survey context across 3D generation, useful for landscape mapping but less directly actionable than the model-specific references above
- Sources: <https://huggingface.co/papers/2401.17807>

### Show HN: Real-Time 3D Gaussian Splatting in WebGL

- Date: September 11, 2023
- Authors / affiliations: open-source browser implementation by `antimatter15`
- Relevance: 4/5
- Impact signal: 309 HN points and 59 comments
- Why it matters: this is one of the best engineering discussions I found for the practical consequences of Gaussian splats. The comments focus less on the novelty of the paper and more on renderer behavior, projection math, control schemes, browser performance, and the path from research representation to real deployment.
- Sources: <https://news.ycombinator.com/item?id=37470611>, <https://github.com/antimatter15/splat>

### Splatt3R: Zero-Shot Gaussian Splatting from Uncalibrated Image Pairs

- Date: August 2024 HN discussion of the paper and demo
- Authors / affiliations: linked paper discussed on HN builds on MASt3R and related work; I am using this entry primarily as an HN-linked directional citation rather than a fully normalized bibliography item
- Relevance: 4/5
- Impact signal: 145 HN points and 27 comments
- Why it matters: this thread is valuable because it makes the current transition legible: from classical camera solving and optimization-heavy splat pipelines toward learned priors that can infer poses and Gaussian parameters from only a few uncalibrated images.
- Sources: <https://news.ycombinator.com/item?id=41366006>

### Deblur-GS: 3D Gaussian splatting from camera motion blurred images

- Date: May 13, 2024 HN discussion
- Authors / affiliations: HN-linked paper discussion; formal affiliations not captured in the source snippet I used
- Relevance: 3/5
- Impact signal: 170 HN points and 38 comments
- Why it matters: worth including because it surfaces a concrete robustness question that general literature reviews often skip. The HN discussion centers on whether splat pipelines can handle realistic shaky-phone input rather than only clean captures.
- Sources: <https://news.ycombinator.com/item?id=40345654>

### Turn a single image into a navigable 3D Gaussian Splat with depth

- Date: 2026 HN discussion of a SHARP-based demo
- Authors / affiliations: demo discussed on HN; comments explicitly identify Apple SHARP as the underlying monocular depth method
- Relevance: 3/5
- Impact signal: 85 HN points and 40 comments
- Why it matters: useful as an applied bridge between Apple's monocular depth work and splat-style scene viewing from a single image. The discussion also crisply contrasts monocular generative completion with multi-view photogrammetry and NeRF-style reconstruction.
- Sources: <https://news.ycombinator.com/item?id=46557352>, <https://apple.github.io/ml-sharp/>

### World Labs: Generate 3D worlds from a single image

- Date: December 2, 2024 HN discussion
- Authors / affiliations: World Labs; discussion also notes Fei-Fei Li as a co-founder
- Relevance: 4/5
- Impact signal: 487 HN points and 135 comments
- Why it matters: this is a useful HN-only citation because the thread surfaces the main product-level criticism of single-image world generation: near-field results can look compelling, but exploration radius, structural consistency, and off-camera geometry remain the bottlenecks. It is a good complement to the more object-centric papers in the main bibliography.
- Sources: <https://news.ycombinator.com/item?id=42297644>

### Scaniverse / Object Capture discussion on HN

- Date: January 1, 2023 HN subthread
- Authors / affiliations: product discussion around Niantic Scaniverse and Apple Object Capture
- Relevance: 3/5
- Impact signal: I am not using score here because this is a contextual subthread rather than a front-page standalone post
- Why it matters: worth keeping as an applied citation because it captures an enduring product-level distinction: LiDAR-first mobile capture is fast and convenient, but lower-resolution than good photogrammetry for fine object detail and 3D printing workflows.
- Sources: <https://news.ycombinator.com/item?id=34211954>, <https://scaniverse.com/>, <https://developer.apple.com/augmented-reality/object-capture/>
