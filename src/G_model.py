import time
import os
import random

import pandas as pd
import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader


class GDataset(Dataset):
    def __init__(self, x_file, y_file, geno_file):
        x = pd.read_csv(x_file)
        y = pd.read_csv(y_file)
        x = x.merge(y, on=['Env', 'Hybrid'], how='left')
        del y

        geno = pd.read_csv(
            geno_file,
            dtype='int8',
            nrows=100,
            usecols=lambda col: col in x['Hybrid'].unique()
        )
        # self.samples = geno.columns.tolist()

        geno = geno.T
        geno.columns = [f'snp{i}' for i in range(geno.shape[1])]
        self.snps = geno.columns.tolist()
        geno = geno.reset_index().rename(columns={'index': 'Hybrid'})
        self.df = x.merge(geno, on='Hybrid', how='inner')

    def __len__(self):
        return len(self.df)

    def __getitem__(self, idx):
        return {
            'x': torch.tensor(self.df[self.snps].iloc[idx], dtype=torch.float32),  # [n_snps, 1]
            'y': torch.tensor(self.df['Yield_Mg_ha'].iloc[idx], dtype=torch.float32).unsqueeze(0)  # [1, 1]
            # 'Env': self.df['Env'].iloc[idx],
            # 'Hybrid': self.df['Hybrid'].iloc[idx]
        }


class GModel(nn.Module):
    def __init__(self, input_size, hidden_size, output_size):
        super(GModel, self).__init__()
        self.fc1 = nn.Linear(input_size, hidden_size)
        self.fc2 = nn.Linear(hidden_size, output_size)
        self.dropout1 = nn.Dropout(p=0.2)

    def forward(self, x):
        x = torch.relu(self.fc1(x))
        x = self.dropout1(x)
        x = self.fc2(x)
        return x


def seed_everything(seed: int):
    random.seed(seed)
    os.environ['PYTHONHASHSEED'] = str(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed(seed)
    # torch.backends.cudnn.deterministic = True
    # torch.backends.cudnn.benchmark = True


def rmse_by_env(ypred, ytrue, env):
    pass
    


if __name__ == '__main__':

    start_time = time.perf_counter()

    seed_everything(42)

    # Create an instance of the dataset
    train_dataset = GDataset('output/xtrain.csv', 'output/ytrain.csv', 'output/genotype.csv')

    # Create a dataloader to feed the data to the model
    train_dataloader = DataLoader(train_dataset, batch_size=32, shuffle=True)

    # The same for validation set
    val_dataset = GDataset('output/xval.csv', 'output/yval.csv', 'output/genotype.csv')
    val_dataloader = DataLoader(val_dataset, batch_size=32, shuffle=False)  # no shuffle here

    # Create an instance of the model
    input_size = len(train_dataset[0]['x'])
    hidden_size = 64
    output_size = 1
    num_epochs = 20
    model = GModel(input_size, hidden_size, output_size)

    # Define the loss function and optimizer
    criterion = nn.MSELoss()
    optimizer = torch.optim.Adam(model.parameters(), lr=0.001)

    # Train the model and evaluate
    for epoch in range(num_epochs):
        for batch in train_dataloader:
            xtrain = batch['x']
            ytrain = batch['y']

            # Forward pass
            ypred_train = model(xtrain)
            loss = criterion(ypred_train, ytrain) ** 0.5

            # Backward pass and optimization
            optimizer.zero_grad()
            loss.backward()
            optimizer.step()

        # Evaluate the model on the validation set
        model.eval()  # set the model to evaluation mode
        with torch.no_grad():  # temporarily set all the requires_grad flag to false
            val_loss = 0
            for batch in val_dataloader:
                xval = batch['x']
                yval = batch['y']

                # Forward pass
                ypred_val = model(xval)
                val_loss += (criterion(ypred_val, yval) ** 0.5).item()
            val_loss /= len(val_dataloader)
        print(f'Epoch: {epoch + 1}/{num_epochs}, RMSE (train): {loss.item():.4f}, RMSE (val): {val_loss:.4f}')
        model.train()  # set the model back to training mode

    end_time = time.perf_counter()
    total_time = (end_time - start_time) / 60
    print('Total minutes:', round(total_time, 2))

