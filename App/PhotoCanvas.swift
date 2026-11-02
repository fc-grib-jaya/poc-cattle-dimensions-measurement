import SwiftUI

@MainActor struct PhotoCanvas:View {
    let image:UIImage
    let target:CGRect
    let pose:[Landmark]
    let landmarks:[Landmark]
    let activeID:String
    let selecting:Bool
    let enabled:Bool
    let onTarget:(CGRect)->Void
    let onMove:(String,Point2)->Void
    @State private var dragID:String?
    @State private var draft:CGRect?
    var body:some View {
        GeometryReader {g in
            let scale=min(g.size.width/image.size.width,g.size.height/image.size.height)
            let size=CGSize(width:image.size.width*scale,height:image.size.height*scale)
            let origin=CGPoint(x:(g.size.width-size.width)/2,y:(g.size.height-size.height)/2)
            ZStack(alignment:.topLeading) {
                Color.black
                Image(uiImage:image).resizable().frame(width:size.width,height:size.height).offset(x:origin.x,y:origin.y)
                let box=draft ?? target
                Rectangle().stroke(selecting ? Color.orange : Color.white.opacity(0.5),style:StrokeStyle(lineWidth:2,dash:[6,4]))
                    .frame(width:box.width*size.width,height:box.height*size.height)
                    .offset(x:origin.x+box.minX*size.width,y:origin.y+box.minY*size.height)
                ForEach(pose) {p in
                    Circle().fill(.white.opacity(0.85)).frame(width:6,height:6).position(x:origin.x+p.point.x*size.width,y:origin.y+p.point.y*size.height)
                }
                if let top=landmarks.first(where:{$0.id=="chestTop"}),let bottom=landmarks.first(where:{$0.id=="chestBottom"}) {
                    Path {path in
                        path.move(to:CGPoint(x:origin.x+top.point.x*size.width,y:origin.y+top.point.y*size.height))
                        path.addLine(to:CGPoint(x:origin.x+bottom.point.x*size.width,y:origin.y+bottom.point.y*size.height))
                    }.stroke(.yellow,style:StrokeStyle(lineWidth:2,dash:[5,3]))
                }
                if let a=landmarks.first(where:{$0.id=="shoulder"}),let b=landmarks.first(where:{$0.id=="pin"}) {
                    Path {path in
                        path.move(to:CGPoint(x:origin.x+a.point.x*size.width,y:origin.y+a.point.y*size.height))
                        path.addLine(to:CGPoint(x:origin.x+b.point.x*size.width,y:origin.y+b.point.y*size.height))
                    }.stroke(.mint,lineWidth:2)
                }
                ForEach(landmarks) {p in
                    ZStack {
                        Circle().fill(p.id==activeID ? Color.mint : Color.teal).frame(width:30,height:30)
                        Text(String(p.label.prefix(1))).font(.caption.bold()).foregroundStyle(.black)
                    }.position(x:origin.x+p.point.x*size.width,y:origin.y+p.point.y*size.height)
                }
            }.contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance:0).onChanged {value in
                guard enabled else {return}
                func normalized(_ p:CGPoint)->Point2 {.init(min(1,max(0,(p.x-origin.x)/size.width)),min(1,max(0,(p.y-origin.y)/size.height)))}
                let start=normalized(value.startLocation),end=normalized(value.location)
                guard CGRect(origin:origin,size:size).contains(value.startLocation) else {return}
                if selecting {
                    draft=CGRect(x:min(start.x,end.x),y:min(start.y,end.y),width:abs(start.x-end.x),height:abs(start.y-end.y))
                } else {
                    if dragID == nil {
                        let near=landmarks.min {a,b in
                            hypot((a.point.x-start.x)*size.width,(a.point.y-start.y)*size.height)<hypot((b.point.x-start.x)*size.width,(b.point.y-start.y)*size.height)
                        }
                        if let near=near,hypot((near.point.x-start.x)*size.width,(near.point.y-start.y)*size.height)<30 {dragID=near.id}
                        else {dragID=activeID}
                    }
                    onMove(dragID ?? activeID,end)
                }
            }.onEnded {_ in
                if selecting,let d=draft,d.width>0.08,d.height>0.08 {onTarget(d)}
                draft=nil;dragID=nil
            })
        }.clipShape(RoundedRectangle(cornerRadius:18))
    }
}
