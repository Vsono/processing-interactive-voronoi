import java.util.Collections;

class Edge {
    Circumcircle a, b;

    Edge(Circumcircle a, Circumcircle b) {
        this.a = a;
        this.b = b;
    }

    Circumcircle other_point(Circumcircle x) {
        if(a == x) return b;
        if(b == x) return a;
        return null;
    }
}

class Circumcircle {
    Segment a, b, c; //triangle vertices

    PVector center;
    float r;

    Circumcircle(Segment a, Segment b, Segment c, PVector center, float r) {
        this.a = a;
        this.b = b;
        this.c = c;
        this.center = center;
        this.r = r;
    }

    boolean do_touch(Circumcircle other) {
        if(a == other.a || a == other.b || a == other.c) {
            return b == other.a || b == other.b || b == other.c || c == other.a || c == other.b || c == other.c;
        }
        else {
            return (b == other.a || b == other.b || b == other.c) && (c == other.a || c == other.b || c == other.c);
        }
    }
}

class Segment {
    ArrayList<Edge> seg_edges = new ArrayList<Edge>();
    PVector center;

    void add_edge(Edge e) {
        seg_edges.add(e);
    }

    ArrayList<PVector> vertices() {
        if(seg_edges.size() == 0) return null;

        ArrayList<PVector> verticesList = new ArrayList<PVector>();
        Circumcircle start = seg_edges.get(0).a;
        Circumcircle before = start;
        Circumcircle moving_to = seg_edges.get(0).b;

        verticesList.add(before.center);



        while(moving_to != start) {
            boolean found = false;
            for(Edge edge : seg_edges) {
                Circumcircle next = edge.other_point(moving_to);
                
                if(next != null && next != before) {
                    // found 
                    verticesList.add(moving_to.center);
                    before = moving_to;
                    moving_to = next;
                    found = true;
                    break;
                }
            }

            if(!found) return null;
        }
        return verticesList;
    }
}


final int SCR_WIDTH = 960;
final int SCR_HEIGHT = 960;

Segment[] segments = new Segment[30];

ArrayList<Edge> edges;
ArrayList<Circumcircle> circles;

void setup() {
    size(960, 960);
    colorMode(HSB, segments.length, 255, 255);

    generate();
}

void generate() {
    for(int i = 0; i < segments.length; i++){
        segments[i] = new Segment();
        segments[i].center = new PVector(random(200, SCR_WIDTH - 200), random(200, SCR_HEIGHT - 200));
    }

    segments[0].center.x = -SCR_WIDTH;
    segments[0].center.y = -SCR_HEIGHT;

    segments[1].center.x = -SCR_WIDTH;
    segments[1].center.y = SCR_HEIGHT * 2;

    segments[2].center.x = SCR_WIDTH * 2;
    segments[2].center.y = SCR_HEIGHT * 2;

    segments[3].center.x = SCR_WIDTH * 2;
    segments[3].center.y = -SCR_HEIGHT;

    solve();
}

void solve() {
    for(Segment s : segments) s.seg_edges = new ArrayList<Edge>();
    edges = new ArrayList<Edge>();
    circles = new ArrayList<Circumcircle>();

    // this part is extremely inefficient.
    // better to implement Delaunay triangulation or Fortune's algorithm
    
    for(int i = 0; i < segments.length - 2; i++){
        for(int j = i + 1; j < segments.length - 1; j++){
            for(int k = j + 1; k < segments.length; k++){
                PVector a = segments[i].center;
                PVector b = segments[j].center;
                PVector c = segments[k].center;

                float iD = 1 / (2*(a.x*(b.y - c.y) + b.x*(c.y - a.y) + c.x*(a.y - b.y)));
                float x = (
                    (a.x*a.x + a.y*a.y) * (b.y - c.y) +
                    (b.x*b.x + b.y*b.y) * (c.y - a.y) +
                    (c.x*c.x + c.y*c.y) * (a.y - b.y)
                ) * iD;
                float y = (
                    (a.x*a.x + a.y*a.y) * (c.x - b.x) +
                    (b.x*b.x + b.y*b.y) * (a.x - c.x) +
                    (c.x*c.x + c.y*c.y) * (b.x - a.x)
                ) * iD;
                float radius = PVector.sub(new PVector(x, y), a).mag();

                PVector center = new PVector(x, y);

                boolean ok = true;
                for(int l = 0; l < segments.length; l++) {
                    if(segments[l].center == a || segments[l].center == b || segments[l].center == c) continue;

                    if(PVector.sub(segments[l].center, center).mag() < radius) {
                        ok = false;
                        break;
                    }
                }

                if(ok)
                    circles.add(new Circumcircle(segments[i], segments[j], segments[k], center, radius));
            }
        }
    }

    for(int i = 0; i < circles.size() - 1; i++) {
        for(int j = i + 1; j < circles.size(); j++) {
            if(circles.get(i).do_touch(circles.get(j))) {
                edges.add(new Edge(circles.get(i), circles.get(j)));
            }
        }
    }

    for(Edge edge : edges) {
        Circumcircle circleA = edge.a;
        Circumcircle circleB = edge.b;

        ArrayList<Segment> commons = new ArrayList<Segment>();

        if(circleA.a == circleB.a || circleA.a == circleB.b || circleA.a == circleB.c) {
            commons.add(circleA.a);
        }
        if(circleA.b == circleB.a || circleA.b == circleB.b || circleA.b == circleB.c) {
            commons.add(circleA.b);
        }
        if(circleA.c == circleB.a || circleA.c == circleB.b || circleA.c == circleB.c) {
            commons.add(circleA.c);
        }

        if(commons.size() == 2) {
            commons.get(0).add_edge(edge);
            commons.get(1).add_edge(edge);
        }
    }
}

void mouseDragged() {
    segments[segments.length - 1].center.x = mouseX;
    segments[segments.length - 1].center.y = mouseY;
    solve();
    loop();
}

void mousePressed() {
    if(mouseButton == LEFT) {
        PVector[] centers = new PVector[segments.length + 1];
        for(int i = 0; i < segments.length; i++) {
            centers[i] = segments[i].center;
        }

        centers[segments.length] = new PVector(mouseX, mouseY);

        segments = new Segment[segments.length + 1];
        for(int i = 0; i < segments.length; i++) {
            segments[i] = new Segment();
            segments[i].center = centers[i];
        }

        colorMode(HSB, segments.length, 255, 255);
        solve();
        loop();
    }
}

void mouseClicked() {
    if(mouseButton == RIGHT) {
        randomSeed(int(random(10000000)));
        generate();
        loop();
    }
}

void keyPressed() {
    if(key == ' ') {
        println("start saving...");
    }
}

void draw() {
    background(0, 0, 255);
    strokeWeight(1);

    // draw voronoi
    // for(int i = 0; i < SCR_WIDTH; i++) {
    //     for(int j = 0; j < SCR_HEIGHT; j++) {
    //         PVector pos = new PVector(i, j);

    //         float mindist = 10000000;
    //         int idx = -1;

    //         for(int v = 0; v < segments.length; v++) {
    //             float dist = PVector.sub(pos, segments[v].center).magSq();
    //             if(dist < mindist){
    //                 mindist = dist;
    //                 idx = v;
    //             }
    //         }

    //         if(idx >= 0) {
    //             stroke(idx, 255, 100, 255);
    //             point(i, j);
    //         }
    //     }
    // }


    noFill();
    stroke(0, 0, 255, 50);
    for(Circumcircle circle : circles) {
        arc(circle.center.x, circle.center.y, circle.r * 2, circle.r * 2, 0, PI * 2);
        arc(circle.center.x, circle.center.y, 10, 10, 0, PI * 2);
    }

    strokeWeight(3);
    stroke(0, 0, 255, 255);
    for(int i = 0; i < segments.length; i++) {
        ArrayList<PVector> verticeslist = segments[i].vertices();

        if(verticeslist != null){
            fill(i, 255, 255, 150);
            beginShape();
            for(PVector vtx : verticeslist) {
                vertex(vtx.x, vtx.y);
            }
            endShape(CLOSE);
        }
    }
    
    noFill();
    strokeWeight(1);
    stroke(0, 0, 0, 255);
    for(Segment segment : segments) {
        arc(segment.center.x, segment.center.y, 5, 5, 0, PI * 2);
    }

    noLoop();
}