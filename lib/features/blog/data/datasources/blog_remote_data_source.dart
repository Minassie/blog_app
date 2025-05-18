import 'dart:io';
import 'package:blog_app/core/error/exceptions.dart';
import 'package:blog_app/features/blog/data/models/blog_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

abstract interface class BlogRemoteDataSource {
  Future<BlogModel> uploadBlog(BlogModel blog);
  Future<String> uploadBlogImage({
    required File image,
    required BlogModel blog,
  });
  Future<List<BlogModel>> getAllBlogs();
}

class BlogRemoteDataSourceImpl implements BlogRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  BlogRemoteDataSourceImpl(this.firestore, this.storage);

  @override
  Future<BlogModel> uploadBlog(BlogModel blog) async {
    try {
      final blogRef = firestore.collection('blogs').doc(blog.id);
      await blogRef.set(blog.toJson());
      final blogSnapshot = await blogRef.get();
      return BlogModel.fromJson(blogSnapshot.data()!);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<String> uploadBlogImage({
    required File image,
    required BlogModel blog,
  }) async {
    try {
      final storageRef = storage.ref().child('blog_images/${blog.id}');
      await storageRef.putFile(image);
      final imageUrl = await storageRef.getDownloadURL();
      return imageUrl;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<BlogModel>> getAllBlogs() async {
    try {
      final blogSnapshot = await firestore.collection('blogs').get();
      final blogs = <BlogModel>[];
      for (var blogDoc in blogSnapshot.docs) {
        final blog = BlogModel.fromJson(blogDoc.data());
        // Fetch poster name from profiles collection
        final userDoc =
            await firestore.collection('profiles').doc(blog.posterId).get();
        if (userDoc.exists) {
          blogs.add(blog.copyWith(posterName: userDoc.data()?['name']));
        }
      }
      return blogs;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}