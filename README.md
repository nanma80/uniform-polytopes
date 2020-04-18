# Near-miss ball-and-stick model

Back in high school, I made a paper model of this shape (I don't have photos of the original model). 

![ball-and-stick model](https://raw.githubusercontent.com/nanma80/uniform-polytopes/master/output/omni_120/omni_120_faces_2.png "ball-and-stick model")

It's roughly a ball-and-stick model, where balls are truncated octahedra, and sticks are hexagonal prisms. This model is unique because it is "invalid". A truncated octahedron provides an angle of 109.5 degrees ( arccos(-1/3) ). However, the pentagon requires an angle of 108 degrees. It misses by 1.5 degrees. In reality it should have thin gaps (thin black lines between polyhedra) like this:

![with gap](https://raw.githubusercontent.com/nanma80/uniform-polytopes/master/output/omni_120/omni_120_faces_2_net.png "with gap")

On a paper model, however, the gaps were barely noticable. Essentially I forced the paper model to bend a bit.

Several years later, I found that this near-miss construction is not a mere coincidence. It is part of the 4D omnitruncated 120-cell. See [Eusebeia's page](http://eusebeia.dyndns.org/4d/omni120cell) for pictures of this 4D polytope. The polyhedra fit together there because they "fold" to the 4th dimension. To construct part of the omnitruncated 120-cell, we start from a truncated icosidodecahedron.
![truncated icosidodecahedron](https://raw.githubusercontent.com/nanma80/uniform-polytopes/master/output/omni_120/omni_120_faces_1_net.png "truncated icosidodecahedron")

Then, we attach a truncated octahedron on each of its hexagonal face, and a hexagonal prism on each of its square face. If we only live in 3D space without using the 4th dimension, we see tiny gaps like in the previous picture.

![net](https://raw.githubusercontent.com/nanma80/uniform-polytopes/master/output/omni_120/omni_120_faces_3_net.png "Net")

This is part of the "net" of the polytope. Then we fold them a little bit so that the gaps disappear.

![folded](https://raw.githubusercontent.com/nanma80/uniform-polytopes/master/output/omni_120/omni_120_faces_3.png "folded")

As an analogy, consider fitting three pentagons on a plane around a point. They cover 108 * 3 = 324 out of 360 degrees, leaving a gap of 36 degrees. If we can fold into the 3rd dimension, they fit together to make a corner of a dodecahedron.

In high school, when I bent the paper model to fit the parts together, I actually simulated folding into the 4th dimension!