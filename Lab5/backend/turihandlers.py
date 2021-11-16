#!/usr/bin/python

from pymongo import MongoClient
import tornado.web

from tornado.web import HTTPError
from tornado.httpserver import HTTPServer
from tornado.ioloop import IOLoop
from tornado.options import define, options

from basehandler import BaseHandler

import turicreate as tc
import pickle
from bson.binary import Binary
import json
import numpy as np

class PrintHandlers(BaseHandler):
    def get(self):
        '''Write out to screen the handlers used
        This is a nice debugging example!
        '''
        self.set_header("Content-Type", "application/json")
        self.write(self.application.handlers_string.replace('),','),\n'))

class UploadLabeledDatapointHandler(BaseHandler):
    def post(self):
        '''Save data point and class label to database
        '''
        data = json.loads(self.request.body.decode("utf-8"))

        vals = data['feature']
        fvals = [float(val) for val in vals]
        label = data['label']
        sess  = data['dsid']

        dbid = self.db.labeledinstances.insert(
            {"feature":fvals,"label":label,"dsid":sess}
            );
        self.write_json({"id":str(dbid),
            "feature":[str(len(fvals))+" Points Received",
                    "min of: " +str(min(fvals)),
                    "max of: " +str(max(fvals))],
            "label":label})

class RequestNewDatasetId(BaseHandler):
    def get(self):
        '''Get a new dataset ID for building a new dataset
        '''
        a = self.db.labeledinstances.find_one(sort=[("dsid", -1)])
        if a == None:
            newSessionId = 1
        else:
            newSessionId = float(a['dsid'])+1
        self.write_json({"dsid":newSessionId})

class GetMaxDatasetId(BaseHandler):
    def get(self):
        '''Get a new dataset ID for building a new dataset
        '''
        a = self.db.labeledinstances.find_one(sort=[("dsid", -1)])
        print(a)
        if a == None:
            maxId = 1
        else:
            maxId = float(a['dsid'])
        self.write_json({"dsid":maxId})

class UpdateModelForDatasetId(BaseHandler):
    def get(self):
        '''Train a new model (or update) for given dataset ID
        '''
        dsid = self.get_int_arg("dsid",default=0)

        data = self.get_features_and_labels_as_SFrame(dsid)

        # fit the model to the data
        acc = -1
        best_model = 'unknown'
        if len(data)>0:

            model = tc.classifier.create(data,target='target',verbose=0)# training
            yhat = model.predict(data)
            self.clf[dsid] = model          # Add a pair of id and model to the dict if id not exist
                                            # If it exists it will just update the model
            acc = sum(yhat==data['target'])/float(len(data))
            # save model for use later, if desired
            model.save('../models/turi_model_dsid%d'%(dsid))


        # send back the resubstitution accuracy
        # if training takes a while, we are blocking tornado!! No!!
        self.write_json({"resubAccuracy":acc})

    def get_features_and_labels_as_SFrame(self, dsid):
        # create feature vectors from database
        features=[]
        labels=[]
        for a in self.db.labeledinstances.find({"dsid":dsid}):
            features.append([float(val) for val in a['feature']])
            labels.append(a['label'])

        # convert to dictionary for tc
        data = {'target':labels, 'sequence':np.array(features)}

        # send back the SFrame of the data
        return tc.SFrame(data=data)

class PredictOneFromDatasetId(BaseHandler):
    def post(self):
        '''Predict the class of a sent feature vector
        '''
        data = json.loads(self.request.body.decode("utf-8"))
        fvals = self.get_features_as_SFrame(data['feature'])
        dsid  = data['dsid']
        data = self.get_features_and_labels_as_SFrame(dsid)
        # load the model from the database (using pickle)
        # we are blocking tornado!! no!!
        if dsid not in self.clf:            # If that key does not exist, print a message and return
            self.write("Model does not exist in clf, saving new dsid\n")
            model = tc.classifier.create(data,target='target',verbose=0)# training
            yhat = model.predict(data)
            self.clf[dsid] = model
            acc = sum(yhat==data['target'])/float(len(data))
            # save model for use later, if desired
            model.save('../models/turi_model_dsid%d'%(dsid))
    
        predLabel = self.clf[dsid].predict(fvals);   # If exist, use that model to do the predict
        self.write_json({"prediction":str(predLabel)})

    def get_features_as_SFrame(self, vals):
        # create feature vectors from array input
        # convert to dictionary of arrays for tc

        tmp = [float(val) for val in vals]
        tmp = np.array(tmp)
        tmp = tmp.reshape((1,-1))
        data = {'sequence':tmp}

        # send back the SFrame of the data
        return tc.SFrame(data=data)

    def get_features_and_labels_as_SFrame(self, dsid):
        # create feature vectors from array input
        # convert to dictionary of arrays for tc
        features = []
        labels = []
        for a in self.db.labeledinstances.find({"dsid": dsid}):
            features.append([float(val) for val in a['feature']])
            labels.append(a['label'])

        data = {'target': labels, 'sequence': np.array(features)}

        # send back the SFrame of the data
        return tc.SFrame(data=data)

# ---------------- for lab 5 -----------------
import cv2
import os
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from sklearn.neural_network import MLPClassifier
from sklearn.metrics import accuracy_score, confusion_matrix
from sklearn.decomposition import PCA

class AddImage(BaseHandler):
    def post(self):
        data = json.loads(self.request.body.decode("utf-8"))   
        feature = data['feature']
        label = data['label']
        # ------ plot to check if the image is downgraded successfully
        # np_data = np.array(feature).reshape((207,207))
        # plt.imshow(np_data, cmap=plt.cm.gray))
        # plt.show()
        # featureToStore = list(np_data.flatten())
        self.db.images.insert({
            'label': label,
            'feature': feature
        })
        
# check if there is enough labeled features to train the model
# in our case at least one image for each label(happy, sad, neutral, disgust, surprise, angry, fear)
class CheckData(BaseHandler):
    def get(self):
        check_list = []
        for i in self.db.images.find():
            print(i['label'])
            if i['label'] not in check_list:
                check_list.append(i['label'])
        if len(check_list) == 7:
            self.write_json({'enough': True})
        else: 
            self.write_json({'enough': False})

class TrainModel(BaseHandler):
    def post(self):
        train_data = self.getTrainData()

        # logistic regression
        lr_model = tc.logistic_classifier.create(train_data, target='target', verbose=0)
        lr_yhat = lr_model.predict(train_data)
        lr_acc = sum(lr_yhat == train_data['target'])/float(len(train_data))

        # boosted decision tree
        bdt_model = tc.boosted_trees_classifier.create(train_data, target='target', verbose=0)
        bdt_yhat = bdt_model.predict(train_data)
        bdt_acc = sum(bdt_yhat == train_data['target'])/float(len(train_data))

        print('lr acc:', lr_acc)
        print('bdt acc:', bdt_acc)
        lr_model.save('../models/turi_model_%s' % ('lr_model'))
        bdt_model.save('../models/turi_model_%s' % ('bdt_model'))
        # export to coreml models
        lr_model.export_coreml('../models/%s.mlmodel' % ('lr_model'))
        bdt_model.export_coreml('../models/%s.mlmodel' % ('bdt_model'))

    def getTrainData(self):
        # convert data into sframe data
        features=[]
        labels=[]
        for a in self.db.images.find():
            features.append([float(val) for val in a['feature']])
            labels.append(a['label'])
        data = {'target':labels, 'sequence':np.array(features)}
        return tc.SFrame(data=data)

class PredictLabel(BaseHandler):
    def post(self):
        data = json.loads(self.request.body.decode("utf-8"))   
        model_name = data['model']
        feature = self.get_sframe_feature(data['feature'])
        if model_name == 'LR':
            try:
                model_name = 'lr_model'
            except Exception as e:
                # return None if the model does not exist
                self.write_json({'result': 'None'})
                return
        elif model_name == 'BDT':
            try:
                model_name = 'bdt_model'
            except Exception as e:
                # return None if the model does not exist
                self.write_json({'result': 'None'})
                return
        print('{} making the prediction'.format(model_name))
        # load model from previously saved location
        model = tc.load_model('../models/turi_model_%s' % (model_name))
        pred = model.predict(feature)
        self.write_json({'result': pred[0]})

    def get_sframe_feature(self, feature):
        # convert the feature array to sframe data
        tmp = np.array(feature)
        tmp = tmp.reshape((1, -1))
        data = {'sequence': tmp}
        return tc.SFrame(data=data)

# this checks if there is enough data for comparing two models
class ValidCompare(BaseHandler):
    def get(self):
        check_list = {}
        # counts how many images for each label
        for i in self.db.images.find():
            print(i['label'])
            if i['label'] not in check_list:
                check_list[i['label']] = 1
            else:
                check_list[i['label']] += 1

        if len(check_list) != 7:
            self.write_json({'valid': False})
            return
        
        for key in check_list:
            # requires each label have at least 4 images, because we will do 80:20 split for comparing
            if check_list[key] < 3:
                self.write_json({'valid': False})
                return
        self.write_json({'valid': True})

from sklearn.model_selection import train_test_split     
# similar to train model but the comparing model requires more data and has test data set so that we could have a more reasonable accuracy to compare
class TrainAndCompareModel(BaseHandler):
    def post(self):
        train_data, test_data = self.getTrainData()

        # logistic regression
        lr_model = tc.logistic_classifier.create(train_data, target='target', verbose=0)
        # predict the test data
        lr_yhat = lr_model.predict(test_data)
        lr_acc = sum(lr_yhat == test_data['target'])/float(len(test_data))

        # boosted decision tree
        bdt_model = tc.boosted_trees_classifier.create(train_data, target='target', verbose=0)
        bdt_yhat = bdt_model.predict(test_data)
        bdt_acc = sum(bdt_yhat == test_data['target'])/float(len(test_data))

        print('lr acc:', lr_acc)
        print('bdt acc:', bdt_acc)
        # save and export the newly trained model
        lr_model.save('../models/turi_model_%s' % ('lr_model'))
        bdt_model.save('../models/turi_model_%s' % ('bdt_model'))
        lr_model.export_coreml('../models/%s.mlmodel' % ('lr_model'))
        bdt_model.export_coreml('../models/%s.mlmodel' % ('bdt_model'))

        # convert the accuracy to string so that they can be printed out on UI easily
        lr_acc = '{:.2f}%'.format(lr_acc*100)
        bdt_acc = '{:.2f}%'.format(bdt_acc*100)
        print(lr_acc, bdt_acc)
        # write the json object and send back to server
        self.write_json({'acc': [lr_acc, bdt_acc]})
        # self.write_json({'bdtAcc': bdt_acc})

    def getTrainData(self):
        features=[]
        labels=[]
        for a in self.db.images.find():
            features.append([float(val) for val in a['feature']])
            labels.append(a['label'])

        # 80:20 split based on label stratification. we will use the accuracy on predicting the test data set to compare two models
        X_train, X_test, y_train, y_test = train_test_split(features, labels, test_size = .2, random_state = 1, stratify = labels)
        # convert data into sframe data
        train_data = {'target':y_train, 'sequence':np.array(X_train)}
        test_data = {'target':y_test, 'sequence':np.array(X_test)}
        return tc.SFrame(data=train_data), tc.SFrame(data=test_data)