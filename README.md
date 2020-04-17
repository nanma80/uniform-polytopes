# Near-miss ball-and-stick model

Back in high school, I made a paper model of this (I don't have photos of the original model). 

![ball-and-stick model](https://raw.githubusercontent.com/nanma80/uniform-polytopes/master/output/omni_120/omni_120_faces_2.png "ball-and-stick model")

It's roughly a ball-and-stick model, where balls are truncated octahedra, and sticks are hexagonal prisms. This model is unique because it is not "valid". It's a near miss. A truncated octahedron provides an angle of 109.5 degrees ( arccos(-1/3) ). However, the pentagon requires an angle of 108 degrees. It misses by 1.5 degrees. On a paper model, it was barely noticable, especially because I inserted the "sticks" into the holes of the balls. Essentially I forced the paper model to bend a bit.

Several years later, I found that this near-miss construction is not a mere coincidence. It is part of the omnitruncated 120-cell. See [Eusebeia's page](http://eusebeia.dyndns.org/4d/omni120cell) for pictures. The polyhedra fit together there because they "fold" to the 4th dimension. To construct part of the omnitruncated 120-cell, we start from a great rhombicosidodecahedron.

![great rhombicosidodecahedron](https://raw.githubusercontent.com/nanma80/uniform-polytopes/master/output/omni_120/omni_120_faces_1_net.png "great rhombicosidodecahedron")

Then, we attach a truncated octahedron to each of its hexagonal face, and a hexagonal prism to each of its square face. If we only leave them in the 3D space without using the 4th dimension, we see tiny gaps (thin black lines between polyhedra).

![net](https://raw.githubusercontent.com/nanma80/uniform-polytopes/master/output/omni_120/omni_120_faces_3_net.png "Net")

This is part of the "net" of the polytope. Then we fold them a little bit to the 4th dimension to fill the gaps.

As an analogy, consider fitting three pentagons on a plane around a point. They cover 108 * 3 = 324 out of 360 degrees, leaving a gap of 36 degrees. If we can fold into the 3rd dimension, they fit together to make a corner of a dodecahedron.

In high school, when I bent the paper model to fit the parts together, I actually simulated folding into the 4th dimension.
