const functions = require('firebase-functions');
const admin=require('firebase-admin');
admin.initializeApp();
// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });
exports.onCreateFollower=functions.firestore
.document('/followers/{userId}/userFollowers/{followerId}')
.onCreate(async (snapshot,context)=>{
    const userId=context.params.userId;
    const followerId=context.params.followerId;
    //users followed users posts ref
    const followedUserPostRef=admin.firestore().collection('posts')
    .doc(userId)
    .collection('usersPosts');
    //following user's timeline ref
    const timelinePostRef=admin.firestore().collection('timeline')
    .doc(followerId)
    .collection('timelinePosts');
    //get the followed users post
    const querySnapshot =await followedUserPostRef.get();
    //add each users post to following users timeline
    querySnapshot.forEach(doc=>{
        if(doc.exists){
            const postId=doc.id;
            const postData=doc.data();
            timelinePostRef.doc(postId).set(postData);
        }
    });

});
exports.onDeleteFollower=functions.firestore.document('/followers/{userId}/userFollowers/{followerId}')
.onDelete(async(snapshot,context)=>{
    const userId=context.params.userId;
    const followerId=context.params.followerId;
    const timelinePostRef=admin.firestore().collection('timeline')
    .doc(followerId)
    .collection('timelinePosts');
    const querySnapshot=await timelinePostRef.get();
     querySnapshot.forEach(doc=>{
         console.log(doc.data['ownerId']);
        if(doc.exists){
            doc.ref.delete();
        }
     });
})
exports.onCreatePost=functions.firestore
.document('/posts/{userId}/usersPosts/{postId}')
.onCreate(async(snapshot,context)=>{
    const postCreated=snapshot.data();
    const userId=context.params.userId;
    const postId=context.params.postId;
    //get all thje followers of the user who made post

    const userFollowersRef=admin.firestore()
    .collection('followers')
    .doc(userId)
    .collection('userFollowers');
    const  querySnapshot=await userFollowersRef.get();
    querySnapshot.forEach(doc=>{
        const followerId=doc.id;
        admin.firestore()
        .collection('timeline')
        .doc(followerId)
        .collection('timelinePosts')
        .doc(postId)
        .set(postCreated);
    })
});
exports.onUpdatePost=functions.firestore
.document('/posts/{userId}/usersPosts/{postId}')
.onUpdate(async(change,context)=>{
    const postUpdated=change.after.data();
    const userId=context.params.userId;
    const postId=context.params.postId;
    const userFollowersRef =admin.firestore()
    .collection('followers')
    .doc(userId)
    .collection('userFollowers');
    const querySnapshot=await userFollowersRef.get();
    querySnapshot.forEach(doc=>{
        const followerId=doc.id;
        admin.firestore()
        .collection('timeline')
        .doc(followerId)
        .collection('timelinePosts')
        .doc(postId)
        .get().then(doc=>{
            if(doc.exists){
                doc.ref.update(postUpdated);
            }
        });
    });
    });
    exports.onDeletePost=functions.firestore
    .document('/posts/{userId}/usersPosts/{postId}')
    .onDelete(async(snapshot,context)=>{
        
    const userId=context.params.userId;
    const postId=context.params.postId;
    const userFollowersRef =admin.firestore()
    .collection('followers')
    .doc(userId)
    .collection('userFollowers');
//deleting from followers time line
    const querySnapshot=await userFollowersRef.get();
    querySnapshot.forEach(doc=>{
        const followerId=doc.id;
        admin.firestore()
        .collection('timeline')
        .doc(followerId)
        .collection('timelinePosts')
        .doc(postId)
        .get().then(doc=>{
            if(doc.exists){
                doc.ref.delete();
            }
        });
    });
    });